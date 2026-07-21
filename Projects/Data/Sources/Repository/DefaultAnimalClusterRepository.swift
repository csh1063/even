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
//  - from: "animal", 이름 접두사 "동물 N"

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

    public func clusterAndSaveAlbums() async throws {
        print("\n=== 🐾 [AnimalRepository] 클러스터링 및 앨범 저장 프로세스 시작 ===")
        let context = ModelContext(container)

        let embeddingDescriptor = FetchDescriptor<AnimalEmbeddingEntity>()
        let allEntities = try context.fetch(embeddingDescriptor)
            .sorted { $0.id.uuidString < $1.id.uuidString }

        print("📦 [AnimalRepository] 총 \(allEntities.count)개 임베딩 로드")

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
        let dogOutcome = clusterService.clusterWithLeftoverRetry(embeddings: dogEmbeddings)
        let catOutcome = clusterService.clusterWithLeftoverRetry(embeddings: catEmbeddings)
        let clusterResults = dogOutcome.clusters + catOutcome.clusters
        let leftoverCount = dogOutcome.leftover.count + catOutcome.leftover.count

        print("📊 총 \(clusterResults.count)개 클러스터 생성 (leftover \(leftoverCount)개)")

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

        try context.save()
        print("✅ [AnimalRepository] 저장 완료\n")
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
            print("🚫 블랙리스트 클러스터 스킵")
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
            print("🔄 [\(album.name)] 기존 앨범 재사용")
        } else {
            let centroidData = result.centroid.withUnsafeBytes { Data($0) }
            let albumName = "동물 \(animalIndex)"

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

        for embedding in result.embeddings {
            guard let entity = entityById[embedding.id] else { continue }
            entity.cluster = cluster
            if !cluster.animalEmbeddings.contains(where: { $0.id == entity.id }) {
                cluster.animalEmbeddings.append(entity)
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
        print("✅ [\(album.name)] \(album.photoCount)장")
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
        print("\n=== 🔍 [AnimalRepository] 새 임베딩 \(embeddingIds.count)개 매칭 시작 ===")

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
                print("🚫 제외된 사진 스킵: \(photoId)")
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
            print("✅ 매칭 성공 (유사도: \(String(format: "%.4f", maxSim)))")
        }

        try context.save()
        print("✅ [AnimalRepository] 새 임베딩 매칭 완료\n")
    }

    // MARK: - 앨범 병합

    public func mergeAlbums(sourceId: UUID, targetId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let source = albums.first(where: { $0.id == sourceId }),
              let target = albums.first(where: { $0.id == targetId }) else { return }

        print("\n=== 🔀 [AnimalRepository] 앨범 병합: \(target.name) → \(source.name) ===")

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

        source.photoCount = source.photos.count
        source.isEdited = true

        context.delete(target)
        try context.save()
        print("✅ [AnimalRepository] 병합 완료 — \(source.name): \(source.photoCount)장\n")
    }

    // MARK: - 사진 제외

    public func excludePhoto(photoId: String, fromAlbumId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == fromAlbumId }) else { return }

        print("\n=== 🚫 [AnimalRepository] 사진 제외: \(photoId) from \(album.name) ===")

        for cluster in album.animalClusters {
            if cluster.animalEmbeddings.contains(where: { $0.photo?.localIdentifier == photoId }) {
                cluster.excludedPhotoIds.append(photoId)
            }
        }

        album.photos.removeAll { $0.localIdentifier == photoId }
        album.photoCount = album.photos.count
        album.isEdited = true

        try context.save()
        print("✅ [AnimalRepository] 사진 제외 완료\n")
    }

    // MARK: - 앨범 삭제 + 블랙리스트

    public func deleteAlbum(albumId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == albumId }) else { return }

        print("\n=== 🗑️ [AnimalRepository] 앨범 삭제: \(album.name) ===")

        for cluster in album.animalClusters {
            let ids = cluster.animalEmbeddings.map { $0.id }
            guard !ids.isEmpty else { continue }
            let blacklist = AnimalClusterBlacklistEntity(embeddingIds: ids)
            context.insert(blacklist)
        }

        context.delete(album)
        try context.save()
        print("✅ [AnimalRepository] 앨범 삭제 완료\n")
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

        print("\n=== ✂️ [AnimalRepository] 앨범 분리: \(album.name)에서 \(clustersToSplit.count)개 클러스터 분리 ===")

        let existingAlbumCount = try context.fetchCount(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "animal" }
        ))
        let newAlbumName = "동물 \(existingAlbumCount + 1)"
        let newAlbum = AlbumEntity(
            id: UUID(),
            name: newAlbumName,
            displayName: newAlbumName,
            isAuto: true,
            coverPhotoIdentifier: nil,
            from: "animal"
        )
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
        print("✅ [AnimalRepository] 분리 완료 — \(album.name): \(album.photoCount)장 / \(newAlbum.name): \(newAlbum.photoCount)장\n")
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
