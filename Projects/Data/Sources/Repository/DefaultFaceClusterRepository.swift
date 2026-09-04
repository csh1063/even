//
//  DefaultFaceClusterRepository.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import Foundation
import SwiftData
import Accelerate

public final class DefaultFaceClusterRepository: FaceClusterRepository {
    private let container: ModelContainer
    private let clusterService: FaceClusterService

    public init(container: ModelContainer, clusterService: FaceClusterService) {
        self.container = container
        self.clusterService = clusterService
    }

    // MARK: - 전체 클러스터링 및 앨범 저장

    public func clusterAndSaveAlbums(onProgress: @escaping @Sendable (Double) -> Void) async throws {
        let context = ModelContext(container)

        // 1. DB에서 모든 FaceEmbeddingEntity 로드
        // SwiftData의 fetch 순서 자체가 실행마다 안정적으로 보장되지 않아서, id(UUID) 문자열 기준으로
        // 직접 정렬해 순서를 고정한다 — 안 그러면 Chinese Whispers 내부 순회를 고정해봤자
        // 입력 순서 자체가 매번 달라져서 같은 사진으로 재분석해도 결과가 달라질 수 있다.
        var embeddingDescriptor = FetchDescriptor<FaceEmbeddingEntity>(
            predicate: #Predicate { $0.hasGlasses == false }
        )
        // photo/cluster를 루프 안에서 하나씩 접근하면 SwiftData가 개별로 fault를 해결하며 디스크를
        // 왕복한다(N+1) — 미리 한 번에 당겨와서 이후 접근이 전부 메모리에서 끝나게 한다.
        embeddingDescriptor.relationshipKeyPathsForPrefetching = [\.photo, \.cluster]
        let allEntities = try context.fetch(embeddingDescriptor)
            .sorted { $0.id.uuidString < $1.id.uuidString }

        debugLog("📦 [Repository] 총 \(allEntities.count)개 임베딩 로드")

        guard !allEntities.isEmpty else { return }

        // 블랙리스트 로드
        let blacklists = try context.fetch(FetchDescriptor<ClusterBlacklistEntity>())
        let blacklistSets = blacklists.map { Set($0.embeddingIds) }

        // 기존 face 앨범 수 기준으로 인물 번호 시작
        let existingAlbumCount = try context.fetchCount(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "face" }
        ))

        // 기존 클러스터 로드 — 재실행 시 같은 사람을 새 앨범으로 또 만들지 않고 재사용하기 위함
        var existingClusters = try context.fetch(FetchDescriptor<ClusterEntity>())

        // 클러스터링 — raw cluster 형성에서 버려진 임베딩은 leftover만 모아 최대 3회 재시도한 뒤
        // 전체 라운드의 raw cluster를 합쳐 최종 병합까지 끝낸 결과가 outcome.clusters로 온다
        let embeddings = Array(allEntities.map { $0.toDomain() }.reversed())
        // 클러스터링 자체(0~0.9)와 결과를 앨범에 적용하는 나머지(0.9~1.0)를 나눠서, 클러스터링이
        // 끝난 뒤에도 진행률이 계속 움직이는 것처럼 보이게 한다 — 실제로는 적용 단계가 훨씬 빠르다.
        let outcome = clusterService.clusterWithLeftoverRetry(embeddings: embeddings) { ratio in
            onProgress(ratio * 0.9)
        }

        debugLog("📊 총 \(outcome.clusters.count)개 클러스터 생성 (leftover \(outcome.leftover.count)개)")

        let entityById = Dictionary(uniqueKeysWithValues: allEntities.map { ($0.id, $0) })
        var personIndex = existingAlbumCount + 1
        let dim = 512

        for result in outcome.clusters {
            applyClusterResult(
                result,
                context: context,
                entityById: entityById,
                blacklistSets: blacklistSets,
                existingClusters: &existingClusters,
                personIndex: &personIndex,
                dim: dim
            )
        }

        // 최초 분석(또는 전체 삭제 후 재생성)일 때만 사진 수 기준으로 번호를 다시 매긴다 —
        // 기존 인물 앨범이 이미 있었다면(일반적인 증분 분석) 번호는 건드리지 않는다.
        if existingAlbumCount == 0 {
            renumberAlbums(context: context)
        }

        try context.save()
        onProgress(1.0)
    }

    /// 인물 앨범 전체를 사진 수 내림차순으로 "인물 1"부터 다시 번호 매긴다. 사용자가 직접 이름을
    /// 바꾼 앨범(isRenamed)은 순위 계산엔 포함하되 번호를 소비하지 않고 건너뛴다.
    private func renumberAlbums(context: ModelContext) {
        guard let albums = try? context.fetch(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "face" }
        )) else { return }

        let sorted = albums.filter { !$0.isRenamed }.sorted { $0.photoCount > $1.photoCount }
        for (index, album) in sorted.enumerated() {
            let newName = "인물 \(index + 1)"
            album.name = newName
            album.displayName = newName
        }
    }

    /// 클러스터 결과 하나를 기존 앨범과 매칭하거나 새 앨범으로 만들어 저장한다. 1차 raw cluster든
    /// leftover 재시도에서 나온 raw cluster든 상관없이 동일하게 "기존 앨범 우선 매칭" 정책이 적용된다.
    private func applyClusterResult(
        _ result: ClusterResult<FaceEmbedding>,
        context: ModelContext,
        entityById: [UUID: FaceEmbeddingEntity],
        blacklistSets: [Set<UUID>],
        existingClusters: inout [ClusterEntity],
        personIndex: inout Int,
        dim: Int
    ) {
        let embeddingIds = Set(result.embeddings.map { $0.id })

        // 블랙리스트 체크
        let isBlacklisted = blacklistSets.contains { blacklistSet in
            let intersection = embeddingIds.intersection(blacklistSet)
            return Double(intersection.count) / Double(blacklistSet.count) >= 0.5
        }
        guard !isBlacklisted else {
            debugLog("🚫 블랙리스트 클러스터 스킵")
            return
        }

        let cluster: ClusterEntity
        let album: AlbumEntity

        // 기존 클러스터 중 centroid가 충분히 비슷한 게 있으면 새로 안 만들고 재사용
        if let matched = findMatchingCluster(centroid: result.centroid, in: existingClusters, dim: dim),
           let matchedAlbum = matched.album {
            cluster = matched
            album = matchedAlbum
            debugLog("🔄 [\(album.name)] 기존 앨범 재사용")
        } else {
            let centroidData = result.centroid.withUnsafeBytes { Data($0) }
            let albumName = "인물 \(personIndex)"

            album = AlbumEntity(
                id: UUID(),
                name: albumName,
                displayName: albumName,
                isAuto: true,
                coverPhotoIdentifier: nil,
                from: "face"
            )
            context.insert(album)
            personIndex += 1

            cluster = ClusterEntity(centroidData: centroidData)
            context.insert(cluster)
            cluster.album = album
            album.clusters.append(cluster)
            existingClusters.append(cluster)
        }

        var currentPhotoIds = Set(album.photos.map { $0.localIdentifier })
        var currentEmbeddingIds = Set(cluster.faceEmbeddings.map { $0.id })

        for embedding in result.embeddings {
            guard let entity = entityById[embedding.id] else { continue }
            entity.cluster = cluster
            if !currentEmbeddingIds.contains(entity.id) {
                cluster.faceEmbeddings.append(entity)
                currentEmbeddingIds.insert(entity.id)
            }

            guard let photo = entity.photo else { continue }
            if !currentPhotoIds.contains(photo.localIdentifier) {
                album.photos.append(photo)
                currentPhotoIds.insert(photo.localIdentifier)
            }
        }

        // 재사용된 클러스터는 새로 합쳐진 멤버 기준으로 centroid 갱신
        updateCentroid(cluster: cluster, dim: dim)

        album.photoCount = album.photos.count

        // 커버는 최신순이 아니라, 이 앨범(병합된 경우 모든 클러스터 포함) 안에서 얼굴 화질(captureQuality)이
        // 가장 좋은 사진으로 고른다. boundingBox 크기(정규화 비율)로 고르면 저해상도 사진 속 얼굴이
        // 고해상도 사진 속 더 작지만 실제로는 더 선명한 얼굴을 이기는 경우가 있어서 화질 점수로 바꿨다.
        // 사용자가 대표 사진을 직접 골랐으면(coverPhotoManuallySet) 이 앨범이 재분석 때마다 다시 매칭돼도
        // 자동으로 덮어쓰지 않는다 — 안 그러면 새 사진이 조금만 들어와도 매번 사용자 선택이 사라진다
        if !album.coverPhotoManuallySet,
           let bestEntity = album.clusters
            .flatMap({ $0.faceEmbeddings })
            .max(by: { $0.captureQuality < $1.captureQuality }),
           let bestPhotoId = bestEntity.photo?.localIdentifier {
            album.coverPhotoIdentifier = bestPhotoId
        }
        debugLog("✅ [\(album.name)] \(album.photoCount)장")
    }

    // 새로 계산된 centroid가 기존 클러스터 중 하나와 충분히 비슷하면 그 클러스터를 반환 (없으면 nil)
    private func findMatchingCluster(centroid: [Float], in clusters: [ClusterEntity], dim: Int, threshold: Float = 0.68) -> ClusterEntity? {
        guard !clusters.isEmpty else { return nil }

        let centroidsFlat: [Float] = clusters.flatMap { cluster -> [Float] in
            cluster.centroidData.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self).prefix(dim))
            }
        }

        let similarities = computeSimilarities(embedding: centroid, centroids: centroidsFlat, clusterCount: clusters.count, dim: dim)
        guard let maxIndex = similarities.indices.max(by: { similarities[$0] < similarities[$1] }) else { return nil }

        return similarities[maxIndex] >= threshold ? clusters[maxIndex] : nil
    }

    // MARK: - 새 임베딩 클러스터 매칭

    public func matchAndAddNewEmbeddings(embeddingIds: [UUID]) async throws {
        guard !embeddingIds.isEmpty else { return }
        debugLog("🔍 새 임베딩 \(embeddingIds.count)개 매칭 시작")

        let context = ModelContext(container)

        let newEntities = try context.fetch(FetchDescriptor<FaceEmbeddingEntity>()).filter {
            embeddingIds.contains($0.id) && !$0.hasGlasses
        }

        let allClusters = try context.fetch(FetchDescriptor<ClusterEntity>())
        guard !allClusters.isEmpty else { return }

        let dim = 512
        let centroidsFlat: [Float] = allClusters.flatMap { cluster -> [Float] in
            cluster.centroidData.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self).prefix(dim))
            }
        }

        for entity in newEntities {
            let embedding: [Float] = entity.embeddingData.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self).prefix(dim))
            }

            let similarities = computeSimilarities(
                embedding: embedding,
                centroids: centroidsFlat,
                clusterCount: allClusters.count,
                dim: dim
            )

            guard let maxIndex = similarities.indices.max(by: { similarities[$0] < similarities[$1] }) else { continue }
            let maxSim = similarities[maxIndex]
            guard maxSim >= 0.68 else { continue }

            let matchedCluster = allClusters[maxIndex]

            if let photoId = entity.photo?.localIdentifier,
               matchedCluster.excludedPhotoIds.contains(photoId) {
                debugLog("🚫 제외된 사진 스킵: \(photoId)")
                continue
            }

            entity.cluster = matchedCluster
            matchedCluster.faceEmbeddings.append(entity)

            if let photo = entity.photo, let album = matchedCluster.album {
                if !album.photos.contains(where: { $0.localIdentifier == photo.localIdentifier }) {
                    album.photos.append(photo)
                    album.photoCount = album.photos.count
                }
            }

            updateCentroid(cluster: matchedCluster, dim: dim)
            debugLog("✅ 매칭 성공 (유사도: \(String(format: "%.4f", maxSim)))")
        }

        try context.save()
    }

    // MARK: - 앨범 병합

    public func mergeAlbums(sourceId: UUID, targetId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let source = albums.first(where: { $0.id == sourceId }),
              let target = albums.first(where: { $0.id == targetId }) else { return }

        // 원래 이름 기억 — 나중에 분리(splitAlbum)할 때 복원용. 이미 기록된 게 있으면(과거에 또
        // 합쳐진 적 있는 클러스터) 덮어쓰지 않아서 제일 처음 이름을 계속 보존한다.
        for cluster in source.clusters where cluster.originalDisplayName == nil {
            cluster.originalName = source.name
            cluster.originalDisplayName = source.displayName
            cluster.originalIsRenamed = source.isRenamed
        }
        for cluster in target.clusters where cluster.originalDisplayName == nil {
            cluster.originalName = target.name
            cluster.originalDisplayName = target.displayName
            cluster.originalIsRenamed = target.isRenamed
        }

        let identity = resolveMergedIdentity(source: source, target: target)

        for cluster in target.clusters {
            cluster.album = source
            if !source.clusters.contains(where: { $0.id == cluster.id }) {
                source.clusters.append(cluster)
            }
        }
        // target.clusters를 비워둬야 한다 — AlbumEntity.clusters는 .cascade 삭제 규칙이라,
        // 방금 source로 옮긴 클러스터가 여전히 target.clusters에 남아있으면 아래 context.delete(target)에서
        // 그 클러스터까지 통째로 같이 삭제돼버린다 (병합했는데 분리할 클러스터가 사라지는 버그의 원인이었음)
        target.clusters.removeAll()

        let existingPhotoIds = Set(source.photos.map { $0.localIdentifier })
        for photo in target.photos where !existingPhotoIds.contains(photo.localIdentifier) {
            source.photos.append(photo)
        }

        source.name = identity.name
        source.displayName = identity.displayName
        source.isRenamed = identity.isRenamed
        source.photoCount = source.photos.count
        source.isEdited = true

        context.delete(target)
        try context.save()
        debugLog("🔀 병합 완료: \(target.name) → \(source.name), 최종 \(source.photoCount)장")
    }

    /// 병합 결과 앨범이 어떤 이름/번호를 가져야 하는지 결정한다 — 둘 다 자동 번호면 낮은 번호,
    /// 어느 한쪽이라도 사용자가 직접 이름을 바꿨으면(isRenamed) 그 이름을 우선한다.
    private func resolveMergedIdentity(source: AlbumEntity, target: AlbumEntity) -> (name: String, displayName: String, isRenamed: Bool) {
        if source.isRenamed && target.isRenamed { return (source.name, source.displayName, true) }
        if target.isRenamed { return (target.name, target.displayName, true) }
        if source.isRenamed { return (source.name, source.displayName, true) }

        let sourceNum = trailingNumber(source.name) ?? Int.max
        let targetNum = trailingNumber(target.name) ?? Int.max
        return targetNum < sourceNum
            ? (target.name, target.displayName, false)
            : (source.name, source.displayName, false)
    }

    private func trailingNumber(_ name: String) -> Int? {
        name.split(separator: " ").last.flatMap { Int($0) }
    }

    // MARK: - 사진 제외

    public func excludePhoto(photoId: String, fromAlbumId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == fromAlbumId }) else { return }

        for cluster in album.clusters {
            if cluster.faceEmbeddings.contains(where: { $0.photo?.localIdentifier == photoId }) {
                cluster.excludedPhotoIds.append(photoId)
            }
        }

        album.photos.removeAll { $0.localIdentifier == photoId }
        album.photoCount = album.photos.count
        album.isEdited = true

        try context.save()
    }

    // MARK: - 앨범 삭제 + 블랙리스트

    public func deleteAlbum(albumId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == albumId }) else { return }

        for cluster in album.clusters {
            let ids = cluster.faceEmbeddings.map { $0.id }
            guard !ids.isEmpty else { continue }
            let blacklist = ClusterBlacklistEntity(embeddingIds: ids)
            context.insert(blacklist)
        }

        context.delete(album)
        try context.save()
    }

    // MARK: - 합칠 앨범 후보 (centroid 유사도 순 정렬)

    /// 이미 계산되어 저장된 클러스터 centroid끼리 내적만 하면 되므로, 앨범 수가 많아도 사실상 즉시 끝난다
    public func fetchOtherFaceAlbumsSortedBySimilarity(excluding albumId: UUID) async throws -> [AlbumMergeCandidate] {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "face" }
        ))
        let others = albums.filter { $0.id != albumId }

        guard let current = albums.first(where: { $0.id == albumId }) else {
            return others.map { AlbumMergeCandidate(album: $0.toDomain(), similarity: -1) }
        }

        let dim = 512
        let currentCentroids: [[Float]] = current.clusters.map { cluster in
            cluster.centroidData.withUnsafeBytes { ptr in Array(ptr.bindMemory(to: Float.self).prefix(dim)) }
        }
        guard !currentCentroids.isEmpty else {
            return others.map { AlbumMergeCandidate(album: $0.toDomain(), similarity: -1) }
        }

        func maxSimilarity(to album: AlbumEntity) -> Float {
            var best: Float = -1
            for cluster in album.clusters {
                let centroid = cluster.centroidData.withUnsafeBytes { ptr -> [Float] in
                    Array(ptr.bindMemory(to: Float.self).prefix(dim))
                }
                for candidate in currentCentroids {
                    var dot: Float = 0
                    vDSP_dotpr(candidate, 1, centroid, 1, &dot, vDSP_Length(dim))
                    best = max(best, dot)
                }
            }
            return best
        }

        let ranked = others
            .map { ($0, maxSimilarity(to: $0)) }
            .sorted { $0.1 > $1.1 }

        return ranked.map { AlbumMergeCandidate(album: $0.0.toDomain(), similarity: $0.1) }
    }

    public func fetchFaceAlbumIds(forPhotoIds photoIds: [String]) async throws -> [UUID] {
        let context = ModelContext(container)

        let ids = Set(photoIds)
        let embeddings = try context.fetch(FetchDescriptor<FaceEmbeddingEntity>())
        let matched = embeddings.filter { entity in
            guard let localIdentifier = entity.photo?.localIdentifier else { return false }
            return ids.contains(localIdentifier)
        }

        let albumIds = matched.compactMap { $0.cluster?.album?.id }
        return Array(Set(albumIds))
    }

    // MARK: - 앨범 분리 (병합 되돌리기)

    public func fetchClusters(albumId: UUID) async throws -> [FaceClusterSummary] {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == albumId }) else { return [] }

        return album.clusters.map { cluster in
            let cover = cluster.faceEmbeddings.max(by: { $0.captureQuality < $1.captureQuality })
            let photoCount = Set(cluster.faceEmbeddings.compactMap { $0.photo?.localIdentifier }).count
            return FaceClusterSummary(id: cluster.id, photoCount: photoCount, coverPhotoId: cover?.photo?.localIdentifier)
        }
    }

    public func splitAlbum(albumId: UUID, clusterIds: [UUID]) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == albumId }) else { return }

        let clustersToSplit = album.clusters.filter { clusterIds.contains($0.id) }
        // 전부 떼어내면 원본 앨범이 텅 비므로, 최소 1개 클러스터는 남아있어야 분리가 성립한다
        guard !clustersToSplit.isEmpty, clustersToSplit.count < album.clusters.count else { return }

        // 분리 대상 클러스터들이 전부 같은 "원래 이름"을 기억하고 있으면(병합되기 전 이름) 그걸로
        // 복원한다 — 새 번호를 매기지 않는다. 기억이 없거나 서로 다르면(여러 앨범이 합쳐진 걸
        // 애매하게 나누는 경우) 기존처럼 새 번호를 매긴다.
        let origins = Set(clustersToSplit.map { $0.originalDisplayName })
        let newAlbumName: String
        let newDisplayName: String
        let newIsRenamed: Bool
        if origins.count == 1,
           let originalDisplayName = clustersToSplit.first?.originalDisplayName,
           let originalName = clustersToSplit.first?.originalName {
            newAlbumName = originalName
            newDisplayName = originalDisplayName
            newIsRenamed = clustersToSplit.first?.originalIsRenamed ?? false
            // 집으로 돌아왔으니 기록 초기화 — 다음에 또 합쳐지면 그때 다시 기록된다
            for cluster in clustersToSplit {
                cluster.originalName = nil
                cluster.originalDisplayName = nil
                cluster.originalIsRenamed = false
            }
        } else {
            let existingAlbumCount = try context.fetchCount(FetchDescriptor<AlbumEntity>(
                predicate: #Predicate { $0.from == "face" }
            ))
            newAlbumName = "인물 \(existingAlbumCount + 1)"
            newDisplayName = newAlbumName
            newIsRenamed = false
        }
        let newAlbum = AlbumEntity(
            id: UUID(),
            name: newAlbumName,
            displayName: newDisplayName,
            isAuto: true,
            coverPhotoIdentifier: nil,
            from: "face"
        )
        newAlbum.isRenamed = newIsRenamed
        context.insert(newAlbum)

        let movingPhotoIds = Set(clustersToSplit.flatMap { $0.faceEmbeddings.compactMap { $0.photo?.localIdentifier } })

        for cluster in clustersToSplit {
            cluster.album = newAlbum
            newAlbum.clusters.append(cluster)
            album.clusters.removeAll { $0.id == cluster.id }
        }

        // 남은 클러스터에도 걸쳐있는 사진(한 사진에 두 사람 얼굴)은 원본 앨범에도 계속 남겨둔다
        let remainingPhotoIds = Set(album.clusters.flatMap { $0.faceEmbeddings.compactMap { $0.photo?.localIdentifier } })
        let photoEntities = Dictionary(uniqueKeysWithValues: album.photos.map { ($0.localIdentifier, $0) })

        for photoId in movingPhotoIds {
            guard let photo = photoEntities[photoId] else { continue }
            if !newAlbum.photos.contains(where: { $0.localIdentifier == photoId }) {
                newAlbum.photos.append(photo)
            }
            if !remainingPhotoIds.contains(photoId) {
                album.photos.removeAll { $0.localIdentifier == photoId }
            }
        }

        album.photoCount = album.photos.count
        newAlbum.photoCount = newAlbum.photos.count
        album.isEdited = true

        if let bestEntity = album.clusters.flatMap({ $0.faceEmbeddings }).max(by: { $0.captureQuality < $1.captureQuality }),
           let bestPhotoId = bestEntity.photo?.localIdentifier {
            album.coverPhotoIdentifier = bestPhotoId
        }
        if let bestEntity = newAlbum.clusters.flatMap({ $0.faceEmbeddings }).max(by: { $0.captureQuality < $1.captureQuality }),
           let bestPhotoId = bestEntity.photo?.localIdentifier {
            newAlbum.coverPhotoIdentifier = bestPhotoId
        }

        try context.save()
        debugLog("✂️ 분리 완료 — \(album.name): \(album.photoCount)장 / \(newAlbum.name): \(newAlbum.photoCount)장")
    }

    // MARK: - Private Helpers

    private func computeSimilarities(embedding: [Float], centroids: [Float], clusterCount: Int, dim: Int) -> [Float] {
        var result = [Float](repeating: 0, count: clusterCount)
        embedding.withUnsafeBufferPointer { embPtr in
            centroids.withUnsafeBufferPointer { centPtr in
                result.withUnsafeMutableBufferPointer { resPtr in
                    cblas_sgemm(
                        CblasRowMajor, CblasNoTrans, CblasTrans,
                        1, Int32(clusterCount), Int32(dim),
                        1.0,
                        embPtr.baseAddress!, Int32(dim),
                        centPtr.baseAddress!, Int32(dim),
                        0.0,
                        resPtr.baseAddress!, Int32(clusterCount)
                    )
                }
            }
        }
        return result
    }

    private func updateCentroid(cluster: ClusterEntity, dim: Int) {
        let embeddings = cluster.faceEmbeddings.compactMap { entity -> [Float]? in
            entity.embeddingData.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self).prefix(dim))
            }
        }
        guard !embeddings.isEmpty else { return }

        var centroid = [Float](repeating: 0, count: dim)
        for emb in embeddings {
            vDSP_vadd(centroid, 1, emb, 1, &centroid, 1, vDSP_Length(dim))
        }
        var count = Float(embeddings.count)
        vDSP_vsdiv(centroid, 1, &count, &centroid, 1, vDSP_Length(dim))
        var normSquared: Float = 0
        vDSP_svesq(centroid, 1, &normSquared, vDSP_Length(dim))
        var norm = sqrt(normSquared)
        if norm > 0 { vDSP_vsdiv(centroid, 1, &norm, &centroid, 1, vDSP_Length(dim)) }
        cluster.centroidData = centroid.withUnsafeBytes { Data($0) }
    }
}
