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
    public var timeWindowMinutes: Double = 1440.0
    /// 1차 클러스터링(윈도우 내)에서 시간 공백 때문에 끊긴 그룹들을,
    /// 시간 제약 없이 centroid(그룹 평균 벡터) 기준으로 한 번 더 병합할 때 쓰는 threshold.
    public var mergeThreshold: Float = 0.45

    private let minSimilarCount: Int = 5

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func clusterAndSaveAlbums(photos: [Photo], existingAlbums: [Album]) async throws {
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

        for i in 0..<sorted.count {
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

        // 7. 앨범 저장
        for (clusterId, groupPhotos) in validGroups {
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
//public final class DefaultSimilarPhotoClusterRepository: SimilarPhotoClusterRepository {
//
//    public var threshold: Float = 0.35
//    public var timeWindowMinutes: Double = 1440.0
//    
//    private let minSimilarCount: Int = 3
//
//    private let container: ModelContainer
//
//    public init(container: ModelContainer) {
//        self.container = container
//    }
//
//    public func clusterAndSaveAlbums(photos: [Photo], existingAlbums: [Album]) async throws {
//        print("\n=== 🚀 [SimilarPhoto] 클러스터링 시작 ===")
//
//        guard !photos.isEmpty else {
//            print("⚠️ [SimilarPhoto] 처리할 데이터 없음")
//            return
//        }
//
//        let context = ModelContext(container)
//        let sorted = photos.sorted { $0.createdAt < $1.createdAt }
//
//        // 1. Union-Find
//        var parent: [String: String] = Dictionary(
//            uniqueKeysWithValues: sorted.map { ($0.localIdentifier, $0.localIdentifier) }
//        )
//
//        func find(_ x: String) -> String {
//            var x = x
//            while parent[x] != x {
//                parent[x] = parent[parent[x]!]!
//                x = parent[x]!
//            }
//            return x
//        }
//
//        func union(_ x: String, _ y: String) {
//            let rx = find(x), ry = find(y)
//            if rx != ry { parent[rx] = ry }
//        }
//
//        // 2. 슬라이딩 윈도우 + 캐시
//        let windowSeconds = timeWindowMinutes * 60
//        var windowStart = 0
//        var cache: [String: VNFeaturePrintObservation] = [:]
//
//        for i in 0..<sorted.count {
//            let iPhoto = sorted[i]
//
//            let prevWindowStart = windowStart
//            while sorted[i].createdAt.timeIntervalSince(sorted[windowStart].createdAt) > windowSeconds {
//                windowStart += 1
//            }
//            for idx in prevWindowStart..<windowStart {
//                cache.removeValue(forKey: sorted[idx].localIdentifier)
//            }
//
//            guard windowStart < i else { continue }
//            let windowSize = i - windowStart + 1
//            guard windowSize >= minSimilarCount else { continue }
//
//            let iObs: VNFeaturePrintObservation?
//            if let cached = cache[iPhoto.localIdentifier] {
//                iObs = cached
//            } else {
//                iObs = await extractFeaturePrint(localIdentifier: iPhoto.localIdentifier)
//            }
//            guard let iObs else { continue }
//            cache[iPhoto.localIdentifier] = iObs
//
//            for j in windowStart..<i {
//                let jPhoto = sorted[j]
//                let jObs: VNFeaturePrintObservation?
//                if let cached = cache[jPhoto.localIdentifier] {
//                    jObs = cached
//                } else {
//                    jObs = await extractFeaturePrint(localIdentifier: jPhoto.localIdentifier)
//                }
//                guard let jObs else { continue }
//                cache[jPhoto.localIdentifier] = jObs
//
//                var distance: Float = 0
//                guard (try? iObs.computeDistance(&distance, to: jObs)) != nil else { continue }
//
//                if distance < threshold {
//                    union(iPhoto.localIdentifier, jPhoto.localIdentifier)
//                }
//            }
//        }
//
//        // 3. 루트별 그룹핑 (2장 이상만)
//        var groups: [String: [Photo]] = [:]
//        for photo in sorted {
//            let root = find(photo.localIdentifier)
//            groups[root, default: []].append(photo)
//        }
//        let validGroups = groups.filter { $0.value.count >= minSimilarCount }
//        print("📊 [SimilarPhoto] \(validGroups.count)개 그룹 생성")
//
//        // 4. DB에서 PhotoEntity 조회용 맵
//        let allIdentifiers = photos.map { $0.localIdentifier }
//        let photoDescriptor = FetchDescriptor<PhotoEntity>(
//            predicate: #Predicate { allIdentifiers.contains($0.localIdentifier) }
//        )
//        let photoEntities = try context.fetch(photoDescriptor)
//        let entityMap = Dictionary(uniqueKeysWithValues: photoEntities.map { ($0.localIdentifier, $0) })
//
//        // 5. 앨범 저장
//        for (clusterId, groupPhotos) in validGroups {
//            let albumName = "similar_\(clusterId)"
//            let album: AlbumEntity
//
//            if existingAlbums.contains(where: { $0.name == albumName }),
//               let existingEntity = try context.fetch(FetchDescriptor<AlbumEntity>(
//                predicate: #Predicate { $0.name == albumName }
//               )).first {
//                album = existingEntity
//            } else {
//                album = AlbumEntity(
//                    name: albumName,
//                    displayName: "유사한 사진",
//                    isAuto: true,
//                    from: "similar"
//                )
//                context.insert(album)
//            }
//
//            var currentIds = Set(album.photos.map { $0.localIdentifier })
//            var added = 0
//
//            for photo in groupPhotos {
//                guard let entity = entityMap[photo.localIdentifier] else { continue }
//                if !currentIds.contains(photo.localIdentifier) {
//                    album.photos.append(entity)
//                    currentIds.insert(photo.localIdentifier)
//                    added += 1
//                }
//            }
//
//            album.photoCount = album.photos.count
//            album.coverPhotoIdentifier = album.photos.sorted { $0.createdAt > $1.createdAt }.first?.localIdentifier
//            print("📝 [SimilarPhoto] [\(albumName)] +\(added)장 / 총 \(album.photoCount)장")
//        }
//
//        // 6. 저장
//        try context.save()
//        print("✅ [SimilarPhoto] 완료\n")
//    }
//
//    // MARK: - Private
//    private func extractFeaturePrint(localIdentifier: String) async -> VNFeaturePrintObservation? {
//        return await withCheckedContinuation { continuation in
//            let options = PHImageRequestOptions()
//            options.isSynchronous = true
//            options.deliveryMode = .fastFormat
//
//            let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
//            guard let asset = result.firstObject else {
//                continuation.resume(returning: nil)
//                return
//            }
//
//            PHImageManager.default().requestImage(
//                for: asset,
//                targetSize: CGSize(width: 224, height: 224),
//                contentMode: .aspectFit,
//                options: options
//            ) { image, _ in
//                guard let cgImage = image?.cgImage else {
//                    continuation.resume(returning: nil)
//                    return
//                }
//
//                let request = VNGenerateImageFeaturePrintRequest()
//                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//                try? handler.perform([request])
//                continuation.resume(returning: request.results?.first as? VNFeaturePrintObservation)
//            }
//        }
//    }
//}
