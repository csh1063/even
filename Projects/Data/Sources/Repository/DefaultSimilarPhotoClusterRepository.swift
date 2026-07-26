//
//  DefaultSimilarPhotoClusterRepository.swift
//  Data
//
//  Created by sanghyeon on 6/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import Vision
import SwiftData
import Photos
import UIKit
import Accelerate

public final class DefaultSimilarPhotoClusterRepository: SimilarPhotoClusterRepository {

    public var threshold: Float = 0.35
    public var timeWindowMinutes: Double = 24 * 60 * 2
    /// 1차 클러스터링(윈도우 내)에서 시간 공백 때문에 끊긴 그룹들을,
    /// 시간 제약 없이 centroid(그룹 평균 벡터) 기준으로 한 번 더 병합할 때 쓰는 threshold.
    public var mergeThreshold: Float = 0.45

    private let minSimilarCount: Int = 2
    /// 1차(윈도우 내)/병합/증분 결과 상관없이, 최종 그룹 크기가 이 값 미만이면 앨범을 만들지 않는다.
    /// minSimilarCount를 2로 낮춘 뒤로 사진 2~3장짜리 앨범이 너무 많이 생겨서 도입.
    private let minimumAlbumSize: Int = 10

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func clusterAndSaveAlbums(
        photos: [Photo],
        existingAlbums: [Album],
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws {
        print("\n=== 🚀 [SimilarPhoto] 클러스터링 시작 ===")

        guard !photos.isEmpty else {
            print("⚠️ [SimilarPhoto] 처리할 데이터 없음")
            return
        }

        let context = ModelContext(container)
        let sorted = photos.sorted { $0.createdAt < $1.createdAt }

        // 1. Union-Find
        var parent: [String: String] = Dictionary(
            uniqueKeysWithValues: sorted.map { ($0.localIdentifier, $0.localIdentifier) }
        )

        func find(_ x: String) -> String {
            var x = x
            while parent[x] != x {
                parent[x] = parent[parent[x]!]!
                x = parent[x]!
            }
            return x
        }

        func union(_ x: String, _ y: String) {
            let rx = find(x), ry = find(y)
            if rx != ry { parent[rx] = ry }
        }

        // 2. 슬라이딩 윈도우 + 캐시
        //    - cache: 윈도우 안에서만 유지 (중복 추출 방지용, 기존과 동일)
        //    - allVectors: 윈도우 밖으로 나가도 삭제하지 않음 → 나중에 centroid 계산에 재사용
        let windowSeconds = timeWindowMinutes * 60
        var windowStart = 0
        var cache: [String: [Float]] = [:]
        var allVectors: [String: [Float]] = [:]

        print("🔎 [SimilarPhoto] 특징 추출 시작 (\(sorted.count)장)")

        // 특징 벡터 추출 + 쌍대 비교가 대부분의 시간을 차지하는 구간 — 1%p 단위로만 진행률 보고 (과도한 호출 방지)
        var lastReportedPercent = -1
        for i in 0..<sorted.count {
            defer {
                let percent = Int((Double(i + 1) / Double(sorted.count)) * 100)
                if percent != lastReportedPercent {
                    lastReportedPercent = percent
                    onProgress(Double(i + 1) / Double(sorted.count))
                    if percent % 10 == 0 {
                        print("⏳ [SimilarPhoto] 특징 추출 진행 \(percent)% (\(i + 1)/\(sorted.count))")
                    }
                }
            }
            let iPhoto = sorted[i]

            let prevWindowStart = windowStart
            while sorted[i].createdAt.timeIntervalSince(sorted[windowStart].createdAt) > windowSeconds {
                windowStart += 1
            }
            for idx in prevWindowStart..<windowStart {
                cache.removeValue(forKey: sorted[idx].localIdentifier)
            }

            guard windowStart < i else { continue }
            let windowSize = i - windowStart + 1
            guard windowSize >= minSimilarCount else { continue }

            let iVec: [Float]?
            if let cached = cache[iPhoto.localIdentifier] {
                iVec = cached
            } else if let existing = allVectors[iPhoto.localIdentifier] {
                iVec = existing
            } else {
                iVec = await extractFeatureVector(localIdentifier: iPhoto.localIdentifier)
            }
            guard let iVec else { continue }
            cache[iPhoto.localIdentifier] = iVec
            allVectors[iPhoto.localIdentifier] = iVec

            for j in windowStart..<i {
                let jPhoto = sorted[j]
                let jVec: [Float]?
                if let cached = cache[jPhoto.localIdentifier] {
                    jVec = cached
                } else if let existing = allVectors[jPhoto.localIdentifier] {
                    jVec = existing
                } else {
                    jVec = await extractFeatureVector(localIdentifier: jPhoto.localIdentifier)
                }
                guard let jVec else { continue }
                cache[jPhoto.localIdentifier] = jVec
                allVectors[jPhoto.localIdentifier] = jVec

                if euclideanDistance(iVec, jVec) < threshold {
                    union(iPhoto.localIdentifier, jPhoto.localIdentifier)
                }
            }
        }

        // 3. 1차 그룹핑 (minSimilarCount 이상만)
        var rawGroups: [String: [Photo]] = [:]
        for photo in sorted {
            let root = find(photo.localIdentifier)
            rawGroups[root, default: []].append(photo)
        }
        let candidateGroups = rawGroups.filter { $0.value.count >= minSimilarCount }
        print("📊 [SimilarPhoto] 1차 그룹 \(candidateGroups.count)개 (윈도우 내)")

        // 4. centroid 기반 그룹 간 재병합 (시간 제약 없음)
        //    윈도우 경계나 체인 중간의 애매한 사진 때문에 같은 장면이 여러 그룹으로
        //    쪼개졌을 때, 그룹 대표 벡터끼리 다시 비교해서 합쳐준다.
        let groupKeys = Array(candidateGroups.keys)
        var centroids: [String: [Float]] = [:]

        for key in groupKeys {
            let vectorsInGroup = candidateGroups[key]!.compactMap { allVectors[$0.localIdentifier] }
            guard let dimension = vectorsInGroup.first?.count else { continue }
            var sum = [Float](repeating: 0, count: dimension)
            for vec in vectorsInGroup {
                for d in 0..<dimension { sum[d] += vec[d] }
            }
            let count = Float(vectorsInGroup.count)
            centroids[key] = sum.map { $0 / count }
        }

        var mergeParent: [String: String] = Dictionary(uniqueKeysWithValues: groupKeys.map { ($0, $0) })

        func mergeFind(_ x: String) -> String {
            var x = x
            while mergeParent[x] != x {
                mergeParent[x] = mergeParent[mergeParent[x]!]!
                x = mergeParent[x]!
            }
            return x
        }

        func mergeUnion(_ x: String, _ y: String) {
            let rx = mergeFind(x), ry = mergeFind(y)
            if rx != ry { mergeParent[rx] = ry }
        }

        for i in 0..<groupKeys.count {
            guard let iCentroid = centroids[groupKeys[i]] else { continue }
            for j in (i + 1)..<groupKeys.count {
                guard let jCentroid = centroids[groupKeys[j]] else { continue }
                if euclideanDistance(iCentroid, jCentroid) < mergeThreshold {
                    mergeUnion(groupKeys[i], groupKeys[j])
                }
            }
        }

        // 5. 최종 그룹 (병합 결과 기준으로 취합)
        var validGroups: [String: [Photo]] = [:]
        for key in groupKeys {
            let mergedRoot = mergeFind(key)
            validGroups[mergedRoot, default: []].append(contentsOf: candidateGroups[key]!)
        }
        print("📊 [SimilarPhoto] 병합 후 \(validGroups.count)개 그룹")

        // 6. DB에서 PhotoEntity 조회용 맵
        let allIdentifiers = photos.map { $0.localIdentifier }
        let photoDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { allIdentifiers.contains($0.localIdentifier) }
        )
        let photoEntities = try context.fetch(photoDescriptor)
        let entityMap = Dictionary(uniqueKeysWithValues: photoEntities.map { ($0.localIdentifier, $0) })

        // 7. 앨범 저장 — 최종 그룹 크기가 minimumAlbumSize 미만이면 앨범을 만들지 않는다
        for (clusterId, groupPhotos) in validGroups {
            guard groupPhotos.count >= minimumAlbumSize else { continue }

            let albumName = "similar_\(clusterId)"
            let album: AlbumEntity

            if existingAlbums.contains(where: { $0.name == albumName }),
               let existingEntity = try context.fetch(FetchDescriptor<AlbumEntity>(
                predicate: #Predicate { $0.name == albumName }
               )).first {
                album = existingEntity
            } else {
                album = AlbumEntity(
                    name: albumName,
                    displayName: "유사한 사진",
                    isAuto: true,
                    from: "similar"
                )
                context.insert(album)
            }

            var currentIds = Set(album.photos.map { $0.localIdentifier })
            var added = 0

            for photo in groupPhotos {
                guard let entity = entityMap[photo.localIdentifier] else { continue }
                if !currentIds.contains(photo.localIdentifier) {
                    album.photos.append(entity)
                    currentIds.insert(photo.localIdentifier)
                    added += 1
                }
            }

            album.photoCount = album.photos.count
            album.coverPhotoIdentifier = album.photos.sorted { $0.createdAt > $1.createdAt }.first?.localIdentifier
            print("📝 [SimilarPhoto] [\(albumName)] +\(added)장 / 총 \(album.photoCount)장")
        }

        // 8. 저장
        try context.save()
        print("✅ [SimilarPhoto] 완료\n")
    }

    public func clusterNewPhotos(
        newPhotos: [Photo],
        allPhotos: [Photo],
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws {
        guard !newPhotos.isEmpty else { return }

        let context = ModelContext(container)
        let sorted = allPhotos.sorted { $0.createdAt < $1.createdAt }
        let newIds = Set(newPhotos.map { $0.localIdentifier })
        let windowSeconds = timeWindowMinutes * 60

        // 새 사진들 기준 전후 windowSeconds 안에 드는 사진(기존+신규)만 비교 대상으로 추출
        var extractIndices = Set<Int>()
        for (i, photo) in sorted.enumerated() where newIds.contains(photo.localIdentifier) {
            var start = i
            while start > 0 && photo.createdAt.timeIntervalSince(sorted[start - 1].createdAt) <= windowSeconds {
                start -= 1
            }
            var end = i
            while end < sorted.count - 1 && sorted[end + 1].createdAt.timeIntervalSince(photo.createdAt) <= windowSeconds {
                end += 1
            }
            for k in start...end { extractIndices.insert(k) }
        }

        let scoped = extractIndices.sorted().map { sorted[$0] }
        guard !scoped.isEmpty else { return }
        print("🔍 [SimilarPhoto] 증분 비교 대상 \(scoped.count)개 (전체 \(sorted.count)개 중, 새 사진 \(newPhotos.count)개)")

        // 1차: 시간 윈도우 슬라이딩 + Union-Find (scoped 대상으로만, 알고리즘은 전체 재계산 버전과 동일)
        var parent: [String: String] = Dictionary(uniqueKeysWithValues: scoped.map { ($0.localIdentifier, $0.localIdentifier) })

        func find(_ x: String) -> String {
            var x = x
            while parent[x] != x {
                parent[x] = parent[parent[x]!]!
                x = parent[x]!
            }
            return x
        }

        func union(_ x: String, _ y: String) {
            let rx = find(x), ry = find(y)
            if rx != ry { parent[rx] = ry }
        }

        var windowStart = 0
        var cache: [String: [Float]] = [:]
        var allVectors: [String: [Float]] = [:]

        var lastReportedPercent = -1
        for i in 0..<scoped.count {
            defer {
                let percent = Int((Double(i + 1) / Double(scoped.count)) * 100)
                if percent != lastReportedPercent {
                    lastReportedPercent = percent
                    onProgress(Double(i + 1) / Double(scoped.count))
                    if percent % 10 == 0 {
                        print("⏳ [SimilarPhoto] 증분 특징 추출 진행 \(percent)% (\(i + 1)/\(scoped.count))")
                    }
                }
            }
            let iPhoto = scoped[i]

            let prevWindowStart = windowStart
            while scoped[i].createdAt.timeIntervalSince(scoped[windowStart].createdAt) > windowSeconds {
                windowStart += 1
            }
            for idx in prevWindowStart..<windowStart {
                cache.removeValue(forKey: scoped[idx].localIdentifier)
            }

            guard windowStart < i else { continue }
            let windowSize = i - windowStart + 1
            guard windowSize >= minSimilarCount else { continue }

            let iVec: [Float]?
            if let cached = cache[iPhoto.localIdentifier] {
                iVec = cached
            } else if let existing = allVectors[iPhoto.localIdentifier] {
                iVec = existing
            } else {
                iVec = await extractFeatureVector(localIdentifier: iPhoto.localIdentifier)
            }
            guard let iVec else { continue }
            cache[iPhoto.localIdentifier] = iVec
            allVectors[iPhoto.localIdentifier] = iVec

            for j in windowStart..<i {
                let jPhoto = scoped[j]
                let jVec: [Float]?
                if let cached = cache[jPhoto.localIdentifier] {
                    jVec = cached
                } else if let existing = allVectors[jPhoto.localIdentifier] {
                    jVec = existing
                } else {
                    jVec = await extractFeatureVector(localIdentifier: jPhoto.localIdentifier)
                }
                guard let jVec else { continue }
                cache[jPhoto.localIdentifier] = jVec
                allVectors[jPhoto.localIdentifier] = jVec

                if euclideanDistance(iVec, jVec) < threshold {
                    union(iPhoto.localIdentifier, jPhoto.localIdentifier)
                }
            }
        }

        var rawGroups: [String: [Photo]] = [:]
        for photo in scoped {
            let root = find(photo.localIdentifier)
            rawGroups[root, default: []].append(photo)
        }
        let candidateGroups = rawGroups.filter { $0.value.count >= minSimilarCount }

        // 2차: centroid 기반 그룹 간 재병합
        let groupKeys = Array(candidateGroups.keys)
        var centroids: [String: [Float]] = [:]

        for key in groupKeys {
            let vectorsInGroup = candidateGroups[key]?.compactMap { allVectors[$0.localIdentifier] } ?? []
            guard let dimension = vectorsInGroup.first?.count else { continue }
            var sum = [Float](repeating: 0, count: dimension)
            for vec in vectorsInGroup {
                for d in 0..<dimension { sum[d] += vec[d] }
            }
            let count = Float(vectorsInGroup.count)
            centroids[key] = sum.map { $0 / count }
        }

        var mergeParent: [String: String] = Dictionary(uniqueKeysWithValues: groupKeys.map { ($0, $0) })

        func mergeFind(_ x: String) -> String {
            var x = x
            while mergeParent[x] != x {
                mergeParent[x] = mergeParent[mergeParent[x]!]!
                x = mergeParent[x]!
            }
            return x
        }

        func mergeUnion(_ x: String, _ y: String) {
            let rx = mergeFind(x), ry = mergeFind(y)
            if rx != ry { mergeParent[rx] = ry }
        }

        for i in 0..<groupKeys.count {
            guard let iCentroid = centroids[groupKeys[i]] else { continue }
            for j in (i + 1)..<groupKeys.count {
                guard let jCentroid = centroids[groupKeys[j]] else { continue }
                if euclideanDistance(iCentroid, jCentroid) < mergeThreshold {
                    mergeUnion(groupKeys[i], groupKeys[j])
                }
            }
        }

        var validGroups: [String: [Photo]] = [:]
        for key in groupKeys {
            let mergedRoot = mergeFind(key)
            validGroups[mergedRoot, default: []].append(contentsOf: candidateGroups[key] ?? [])
        }

        guard !validGroups.isEmpty else {
            print("📊 [SimilarPhoto] 증분 비교 결과 새 그룹 없음")
            return
        }
        print("📊 [SimilarPhoto] 증분 비교로 \(validGroups.count)개 그룹 확인")

        // 3. 결과 그룹을 기존 similar 앨범에 병합하거나 없으면 새로 생성 (기존 앨범은 삭제하지 않음)
        let allIdentifiersInGroups = Set(validGroups.values.flatMap { $0.map { $0.localIdentifier } })
        let photoDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { allIdentifiersInGroups.contains($0.localIdentifier) }
        )
        let photoEntities = try context.fetch(photoDescriptor)
        let entityMap = Dictionary(uniqueKeysWithValues: photoEntities.map { ($0.localIdentifier, $0) })

        for (_, groupPhotos) in validGroups {
            let existingAlbum = groupPhotos
                .compactMap { entityMap[$0.localIdentifier] }
                .compactMap { entity in entity.albums.first(where: { $0.from == "similar" }) }
                .first

            // 이미 있는 앨범에 몇 장 더 붙는 거면 그대로 진행하고, 새로 만드는 경우에만
            // minimumAlbumSize 미만이면 앨범을 만들지 않는다
            guard existingAlbum != nil || groupPhotos.count >= minimumAlbumSize else { continue }

            let album: AlbumEntity
            if let existingAlbum {
                album = existingAlbum
            } else {
                album = AlbumEntity(
                    name: "similar_\(UUID().uuidString)",
                    displayName: "유사한 사진",
                    isAuto: true,
                    from: "similar"
                )
                context.insert(album)
            }

            var currentIds = Set(album.photos.map { $0.localIdentifier })
            var added = 0

            for photo in groupPhotos {
                guard let entity = entityMap[photo.localIdentifier] else { continue }
                if !currentIds.contains(photo.localIdentifier) {
                    album.photos.append(entity)
                    currentIds.insert(photo.localIdentifier)
                    added += 1
                }
            }

            album.photoCount = album.photos.count
            album.coverPhotoIdentifier = album.photos.sorted { $0.createdAt > $1.createdAt }.first?.localIdentifier
            print("📝 [SimilarPhoto] [\(album.name)] +\(added)장 / 총 \(album.photoCount)장")
        }

        try context.save()
        print("✅ [SimilarPhoto] 증분 처리 완료\n")
    }

    // MARK: - Private
    private func extractFeatureVector(localIdentifier: String) async -> [Float]? {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .fastFormat

            let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            guard let asset = result.firstObject else {
                continuation.resume(returning: nil)
                return
            }

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 224, height: 224),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                guard let cgImage = image?.cgImage else {
                    continuation.resume(returning: nil)
                    return
                }

                let request = VNGenerateImageFeaturePrintRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])

                guard let observation = request.results?.first as? VNFeaturePrintObservation,
                      observation.elementType == .float else {
                    continuation.resume(returning: nil)
                    return
                }

                let count = Int(observation.elementCount)
                let values: [Float] = observation.data.withUnsafeBytes { rawBuffer in
                    Array(rawBuffer.bindMemory(to: Float.self).prefix(count))
                }
                continuation.resume(returning: values)
            }
        }
    }

    private func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
        var squaredSum: Float = 0
        vDSP_distancesq(a, 1, b, 1, &squaredSum, vDSP_Length(a.count))
        return squaredSum.squareRoot()
    }
}
