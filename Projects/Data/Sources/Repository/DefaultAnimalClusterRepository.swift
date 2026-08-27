//
//  DefaultAnimalClusterRepository.swift
//  Data
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//  DefaultFaceClusterRepository를 거의 그대로 미러링한다. 다른 점:
//  - 대상 엔티티가 AnimalEmbeddingEntity/AnimalClusterEntity/AnimalClusterBlacklistEntity
//  - 안경(hasGlasses) 필터링 개념이 없음 — 전체 임베딩을 그대로 클러스터링 대상으로 씀
//  - 커버 사진/클러스터 요약 선정 기준이 captureQuality 대신 detectionConfidence
//  - 임베딩 차원이 512가 아니라 384 (DINOv2)
//  - from: "animal", 이름 접두사 "반려동물 N" (종 탐지가 완벽하지 않아 강아지/고양이 구분 없이 통합 번호)

import Domain
import Foundation
import SwiftData
import Accelerate

public final class DefaultAnimalClusterRepository: AnimalClusterRepository {
    private let container: ModelContainer
    private let clusterService: AnimalClusterService
    private let dim = 384

    public init(container: ModelContainer, clusterService: AnimalClusterService) {
        self.container = container
        self.clusterService = clusterService
    }

    // MARK: - 전체 클러스터링 및 앨범 저장

    public func clusterAndSaveAlbums(onProgress: @escaping @Sendable (Double) -> Void) async throws {
        let context = ModelContext(container)

        var embeddingDescriptor = FetchDescriptor<AnimalEmbeddingEntity>()
        // photo/cluster를 루프 안에서 하나씩 접근하면 SwiftData가 개별로 fault를 해결하며 디스크를
        // 왕복한다(N+1) — 미리 한 번에 당겨와서 이후 접근이 전부 메모리에서 끝나게 한다.
        embeddingDescriptor.relationshipKeyPathsForPrefetching = [\.photo, \.cluster]
        let allEntities = try context.fetch(embeddingDescriptor)
            .sorted { $0.id.uuidString < $1.id.uuidString }

        debugLog("📦 [AnimalRepository] 총 \(allEntities.count)개 임베딩 로드")

        guard !allEntities.isEmpty else { return }

        let blacklists = try context.fetch(FetchDescriptor<AnimalClusterBlacklistEntity>())
        let blacklistSets = blacklists.map { Set($0.embeddingIds) }

        let existingAlbumCount = try context.fetchCount(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "animal" }
        ))

        var existingClusters = try context.fetch(FetchDescriptor<AnimalClusterEntity>())

        // 개와 고양이는 임베딩이 아무리 비슷해도 절대 같은 개체일 수 없다 — 유사도 임계값에만 기대지 않고
        // 애초에 종별로 나눠서 따로 클러스터링해서 구조적으로 섞이지 않게 한다
        // (같은 사진 속 서로 다른 개체는 다른 개체라는 규칙과 같은 종류의 "확실한" 제약)
        // raw cluster 형성에서 버려진 임베딩은 leftover만 모아 최대 3회 재시도 — 종이 재시도 라운드에서도
        // 섞이지 않도록 dog/cat 각각 따로 재시도한다
        let embeddings = Array(allEntities.map { $0.toDomain() }.reversed())
        let dogEmbeddings = embeddings.filter { $0.species == .dog }
        let catEmbeddings = embeddings.filter { $0.species == .cat }

        // 개/고양이 순차 처리 두 단계를 각 종의 임베딩 수 비율로 나눠서 0~0.9 구간에 합쳐 보고한다
        // (0.9~1.0은 클러스터링 이후 앨범 적용 단계용) — 한쪽 종이 비어있으면 그 종의 클러스터링은
        // 아예 호출되지 않아 onProgress도 안 불리므로 가중치가 0이어도 문제없다.
        let totalCount = max(embeddings.count, 1)
        let dogWeight = Double(dogEmbeddings.count) / Double(totalCount)
        let catWeight = Double(catEmbeddings.count) / Double(totalCount)

        let dogOutcome = clusterService.clusterWithLeftoverRetry(embeddings: dogEmbeddings) { ratio in
            onProgress(ratio * dogWeight * 0.9)
        }
        let catOutcome = clusterService.clusterWithLeftoverRetry(embeddings: catEmbeddings) { ratio in
            onProgress((dogWeight + ratio * catWeight) * 0.9)
        }
        let clusterResults = dogOutcome.clusters + catOutcome.clusters
        let leftoverCount = dogOutcome.leftover.count + catOutcome.leftover.count

        debugLog("📊 총 \(clusterResults.count)개 클러스터 생성 (leftover \(leftoverCount)개)")

        let entityById = Dictionary(uniqueKeysWithValues: allEntities.map { ($0.id, $0) })
        var animalIndex = existingAlbumCount + 1

        for result in clusterResults {
            applyClusterResult(
                result,
                context: context,
                entityById: entityById,
                blacklistSets: blacklistSets,
                existingClusters: &existingClusters,
                animalIndex: &animalIndex,
                dim: dim
            )
        }

        // 최초 분석(또는 전체 삭제 후 재생성)일 때만 사진 수 기준으로 번호를 다시 매긴다 —
        // 기존 동물 앨범이 이미 있었다면(일반적인 증분 분석) 번호는 건드리지 않는다.
        if existingAlbumCount == 0 {
            renumberAlbums(context: context)
        }

        try context.save()
        onProgress(1.0)
    }

    /// 동물 앨범 전체를 (종 구분 없이) 사진 수 내림차순으로 "반려동물 1"부터 다시 번호 매긴다.
    /// 종 탐지가 완벽하지 않아 강아지/고양이 앨범이 서로 섞이는 경우가 있어서, 종별로 이름을
    /// 따로 붙이면 실제 내용과 안 맞을 수 있어 종 구분 없는 통합 번호로 단순화했다.
    /// 사용자가 직접 이름을 바꾼 앨범(isRenamed)은 순위 계산엔 포함하되 번호를 소비하지 않는다.
    private func renumberAlbums(context: ModelContext) {
        guard let albums = try? context.fetch(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "animal" }
        )) else { return }

        let sorted = albums.filter { !$0.isRenamed }.sorted { $0.photoCount > $1.photoCount }
        for (index, album) in sorted.enumerated() {
            let newName = "반려동물 \(index + 1)"
            album.name = newName
            album.displayName = newName
        }
    }

    /// 클러스터 결과 하나를 기존 앨범과 매칭하거나 새 앨범으로 만들어 저장한다. 1차 raw cluster든
    /// leftover 재시도에서 나온 raw cluster든 상관없이 동일하게 "기존 앨범 우선 매칭" 정책이 적용된다.
    private func applyClusterResult(
        _ result: ClusterResult<AnimalEmbedding>,
        context: ModelContext,
        entityById: [UUID: AnimalEmbeddingEntity],
        blacklistSets: [Set<UUID>],
        existingClusters: inout [AnimalClusterEntity],
        animalIndex: inout Int,
        dim: Int
    ) {
        guard let resultSpecies = result.embeddings.first?.species else { return }
        let embeddingIds = Set(result.embeddings.map { $0.id })

        let isBlacklisted = blacklistSets.contains { blacklistSet in
            let intersection = embeddingIds.intersection(blacklistSet)
            return Double(intersection.count) / Double(blacklistSet.count) >= 0.5
        }
        guard !isBlacklisted else {
            debugLog("🚫 블랙리스트 클러스터 스킵")
            return
        }

        let cluster: AnimalClusterEntity
        let album: AlbumEntity

        // 기존 클러스터 재사용 매칭도 같은 종끼리만 비교한다
        let sameSpeciesExistingClusters = existingClusters.filter { species(of: $0) == resultSpecies.rawValue }

        if let matched = findMatchingCluster(centroid: result.centroid, in: sameSpeciesExistingClusters, dim: dim),
           let matchedAlbum = matched.album {
            cluster = matched
            album = matchedAlbum
            debugLog("🔄 [\(album.name)] 기존 앨범 재사용")
        } else {
            let centroidData = result.centroid.withUnsafeBytes { Data($0) }
            let albumName = "반려동물 \(animalIndex)"

            album = AlbumEntity(
                id: UUID(),
                name: albumName,
                displayName: albumName,
                isAuto: true,
                coverPhotoIdentifier: nil,
                from: "animal"
            )
            context.insert(album)
            animalIndex += 1

            cluster = AnimalClusterEntity(centroidData: centroidData)
            context.insert(cluster)
            cluster.album = album
            album.animalClusters.append(cluster)
            existingClusters.append(cluster)
        }

        var currentPhotoIds = Set(album.photos.map { $0.localIdentifier })
        var currentEmbeddingIds = Set(cluster.animalEmbeddings.map { $0.id })

        for embedding in result.embeddings {
            guard let entity = entityById[embedding.id] else { continue }
            entity.cluster = cluster
            if !currentEmbeddingIds.contains(entity.id) {
                cluster.animalEmbeddings.append(entity)
                currentEmbeddingIds.insert(entity.id)
            }

            guard let photo = entity.photo else { continue }
            if !currentPhotoIds.contains(photo.localIdentifier) {
                album.photos.append(photo)
                currentPhotoIds.insert(photo.localIdentifier)
            }
        }

        updateCentroid(cluster: cluster, dim: dim)

        album.photoCount = album.photos.count

        if let bestEntity = album.animalClusters
            .flatMap({ $0.animalEmbeddings })
            .max(by: { $0.detectionConfidence < $1.detectionConfidence }),
           let bestPhotoId = bestEntity.photo?.localIdentifier {
            album.coverPhotoIdentifier = bestPhotoId
        }
        debugLog("✅ [\(album.name)] \(album.photoCount)장")
    }

    /// 클러스터를 구성하는 임베딩들의 종 — 종별로 분리해서 클러스터링하므로 클러스터 안은 항상 단일 종이다
    private func species(of cluster: AnimalClusterEntity) -> String? {
        cluster.animalEmbeddings.first?.species
    }

    private func findMatchingCluster(centroid: [Float], in clusters: [AnimalClusterEntity], dim: Int, threshold: Float = 0.68) -> AnimalClusterEntity? {
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

        let newEntities = try context.fetch(FetchDescriptor<AnimalEmbeddingEntity>()).filter {
            embeddingIds.contains($0.id)
        }

        let allClusters = try context.fetch(FetchDescriptor<AnimalClusterEntity>())
        guard !allClusters.isEmpty else { return }

        for entity in newEntities {
            // 이 임베딩과 같은 종의 클러스터만 후보로 — 개/고양이는 아무리 비슷해도 매칭 대상이 될 수 없다
            let sameSpeciesClusters = allClusters.filter { species(of: $0) == entity.species }
            guard !sameSpeciesClusters.isEmpty else { continue }

            let embedding: [Float] = entity.embeddingData.withUnsafeBytes { ptr in
                Array(ptr.bindMemory(to: Float.self).prefix(dim))
            }
            let centroidsFlat: [Float] = sameSpeciesClusters.flatMap { cluster -> [Float] in
                cluster.centroidData.withUnsafeBytes { ptr in
                    Array(ptr.bindMemory(to: Float.self).prefix(dim))
                }
            }

            let similarities = computeSimilarities(
                embedding: embedding,
                centroids: centroidsFlat,
                clusterCount: sameSpeciesClusters.count,
                dim: dim
            )

            guard let maxIndex = similarities.indices.max(by: { similarities[$0] < similarities[$1] }) else { continue }
            let maxSim = similarities[maxIndex]
            guard maxSim >= 0.68 else { continue }

            let matchedCluster = sameSpeciesClusters[maxIndex]

            if let photoId = entity.photo?.localIdentifier,
               matchedCluster.excludedPhotoIds.contains(photoId) {
                debugLog("🚫 제외된 사진 스킵: \(photoId)")
                continue
            }

            entity.cluster = matchedCluster
            matchedCluster.animalEmbeddings.append(entity)

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
        for cluster in source.animalClusters where cluster.originalDisplayName == nil {
            cluster.originalName = source.name
            cluster.originalDisplayName = source.displayName
            cluster.originalIsRenamed = source.isRenamed
        }
        for cluster in target.animalClusters where cluster.originalDisplayName == nil {
            cluster.originalName = target.name
            cluster.originalDisplayName = target.displayName
            cluster.originalIsRenamed = target.isRenamed
        }

        let identity = resolveMergedIdentity(source: source, target: target)

        for cluster in target.animalClusters {
            cluster.album = source
            if !source.animalClusters.contains(where: { $0.id == cluster.id }) {
                source.animalClusters.append(cluster)
            }
        }
        target.animalClusters.removeAll()

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
    /// 어느 한쪽이라도 사용자가 직접 이름을 바꿨으면(isRenamed) 그 이름을 우선한다. (종 구분 없는
    /// 통합 번호로 단순화하면서 종이 다른 경우의 별도 규칙은 없앴다 — 어차피 같은 이름 풀을 쓴다)
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

        for cluster in album.animalClusters {
            if cluster.animalEmbeddings.contains(where: { $0.photo?.localIdentifier == photoId }) {
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

        for cluster in album.animalClusters {
            let ids = cluster.animalEmbeddings.map { $0.id }
            guard !ids.isEmpty else { continue }
            let blacklist = AnimalClusterBlacklistEntity(embeddingIds: ids)
            context.insert(blacklist)
        }

        context.delete(album)
        try context.save()
    }

    // MARK: - 합칠 앨범 후보 (centroid 유사도 순 정렬)

    public func fetchOtherAnimalAlbumsSortedBySimilarity(excluding albumId: UUID) async throws -> [AlbumMergeCandidate] {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "animal" }
        ))

        guard let current = albums.first(where: { $0.id == albumId }) else {
            let others = albums.filter { $0.id != albumId }
            return others.map { AlbumMergeCandidate(album: $0.toDomain(), similarity: -1) }
        }

        // 종 라벨은 Vision 탐지 오류로 잘못 찍힐 수 있어서(예: 흰 강아지가 고양이로 오인식) 합치기
        // 후보에서 종으로 미리 걸러내지 않는다 — 자동 클러스터링만 종을 하드 분리하고, 사람이 직접
        // 보고 합치는 이 후보 목록은 유사도 순으로 전부 보여줘서 사용자가 최종 판단하게 한다
        let others = albums.filter { $0.id != albumId }

        let currentCentroids: [[Float]] = current.animalClusters.map { cluster in
            cluster.centroidData.withUnsafeBytes { ptr in Array(ptr.bindMemory(to: Float.self).prefix(dim)) }
        }
        guard !currentCentroids.isEmpty else {
            return others.map { AlbumMergeCandidate(album: $0.toDomain(), similarity: -1) }
        }

        func maxSimilarity(to album: AlbumEntity) -> Float {
            var best: Float = -1
            for cluster in album.animalClusters {
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

    public func fetchAnimalAlbumIds(forPhotoIds photoIds: [String]) async throws -> [UUID] {
        let context = ModelContext(container)

        let ids = Set(photoIds)
        let embeddings = try context.fetch(FetchDescriptor<AnimalEmbeddingEntity>())
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

        return album.animalClusters.map { cluster in
            let cover = cluster.animalEmbeddings.max(by: { $0.detectionConfidence < $1.detectionConfidence })
            let photoCount = Set(cluster.animalEmbeddings.compactMap { $0.photo?.localIdentifier }).count
            return FaceClusterSummary(id: cluster.id, photoCount: photoCount, coverPhotoId: cover?.photo?.localIdentifier)
        }
    }

    public func splitAlbum(albumId: UUID, clusterIds: [UUID]) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == albumId }) else { return }

        let clustersToSplit = album.animalClusters.filter { clusterIds.contains($0.id) }
        guard !clustersToSplit.isEmpty, clustersToSplit.count < album.animalClusters.count else { return }

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
                predicate: #Predicate { $0.from == "animal" }
            ))
            newAlbumName = "반려동물 \(existingAlbumCount + 1)"
            newDisplayName = newAlbumName
            newIsRenamed = false
        }
        let newAlbum = AlbumEntity(
            id: UUID(),
            name: newAlbumName,
            displayName: newDisplayName,
            isAuto: true,
            coverPhotoIdentifier: nil,
            from: "animal"
        )
        newAlbum.isRenamed = newIsRenamed
        context.insert(newAlbum)

        let movingPhotoIds = Set(clustersToSplit.flatMap { $0.animalEmbeddings.compactMap { $0.photo?.localIdentifier } })

        for cluster in clustersToSplit {
            cluster.album = newAlbum
            newAlbum.animalClusters.append(cluster)
            album.animalClusters.removeAll { $0.id == cluster.id }
        }

        let remainingPhotoIds = Set(album.animalClusters.flatMap { $0.animalEmbeddings.compactMap { $0.photo?.localIdentifier } })
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

        if let bestEntity = album.animalClusters.flatMap({ $0.animalEmbeddings }).max(by: { $0.detectionConfidence < $1.detectionConfidence }),
           let bestPhotoId = bestEntity.photo?.localIdentifier {
            album.coverPhotoIdentifier = bestPhotoId
        }
        if let bestEntity = newAlbum.animalClusters.flatMap({ $0.animalEmbeddings }).max(by: { $0.detectionConfidence < $1.detectionConfidence }),
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

    private func updateCentroid(cluster: AnimalClusterEntity, dim: Int) {
        let embeddings = cluster.animalEmbeddings.compactMap { entity -> [Float]? in
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
