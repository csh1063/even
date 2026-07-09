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

    public func clusterAndSaveAlbums() async throws {
        print("\n=== 🚀 [Repository] 클러스터링 및 앨범 저장 프로세스 시작 ===")
        let context = ModelContext(container)

        // 1. DB에서 모든 FaceEmbeddingEntity 로드
        let embeddingDescriptor = FetchDescriptor<FaceEmbeddingEntity>(
            predicate: #Predicate { $0.hasGlasses == false }
        )
        let allEntities = try context.fetch(embeddingDescriptor)

        print("📦 [Repository] 총 \(allEntities.count)개 임베딩 로드")

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

        // 클러스터링
        let embeddings = Array(allEntities.map { $0.toDomain() }.reversed())
        let clusterResults = clusterService.cluster(embeddings: embeddings)

        print("📊 총 \(clusterResults.count)개 클러스터 생성")

        let entityById = Dictionary(uniqueKeysWithValues: allEntities.map { ($0.id, $0) })
        var personIndex = existingAlbumCount + 1
        let dim = 512

        for result in clusterResults {
            let embeddingIds = Set(result.embeddings.map { $0.id })

            // 블랙리스트 체크
            let isBlacklisted = blacklistSets.contains { blacklistSet in
                let intersection = embeddingIds.intersection(blacklistSet)
                return Double(intersection.count) / Double(blacklistSet.count) >= 0.5
            }
            guard !isBlacklisted else {
                print("🚫 블랙리스트 클러스터 스킵")
                continue
            }

            let cluster: ClusterEntity
            let album: AlbumEntity

            // 기존 클러스터 중 centroid가 충분히 비슷한 게 있으면 새로 안 만들고 재사용
            if let matched = findMatchingCluster(centroid: result.centroid, in: existingClusters, dim: dim),
               let matchedAlbum = matched.album {
                cluster = matched
                album = matchedAlbum
                print("🔄 [\(album.name)] 기존 앨범 재사용")
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
            var representativeEntity: FaceEmbeddingEntity?

            for embedding in result.embeddings {
                guard let entity = entityById[embedding.id] else { continue }
                entity.cluster = cluster
                if !cluster.faceEmbeddings.contains(where: { $0.id == entity.id }) {
                    cluster.faceEmbeddings.append(entity)
                }

                guard let photo = entity.photo else { continue }
                if !currentPhotoIds.contains(photo.localIdentifier) {
                    album.photos.append(photo)
                    currentPhotoIds.insert(photo.localIdentifier)
                }
                if representativeEntity == nil { representativeEntity = entity }
            }

            // 재사용된 클러스터는 새로 합쳐진 멤버 기준으로 centroid 갱신
            updateCentroid(cluster: cluster, dim: dim)

            if let rep = representativeEntity {
                album.representativeBoundingBoxX = rep.boundingBoxX
                album.representativeBoundingBoxY = rep.boundingBoxY
                album.representativeBoundingBoxWidth = rep.boundingBoxWidth
                album.representativeBoundingBoxHeight = rep.boundingBoxHeight
            }

            album.photoCount = album.photos.count
            album.coverPhotoIdentifier = album.photos.sorted { $0.createdAt > $1.createdAt }.first?.localIdentifier
            print("✅ [\(album.name)] \(album.photoCount)장")
        }

        try context.save()
        print("✅ [Repository] 저장 완료\n")
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
        print("\n=== 🔍 [Repository] 새 임베딩 \(embeddingIds.count)개 매칭 시작 ===")

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
                print("🚫 제외된 사진 스킵: \(photoId)")
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
            print("✅ 매칭 성공 (유사도: \(String(format: "%.4f", maxSim)))")
        }

        try context.save()
        print("✅ [Repository] 새 임베딩 매칭 완료\n")
    }

    // MARK: - 앨범 병합

    public func mergeAlbums(sourceId: UUID, targetId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let source = albums.first(where: { $0.id == sourceId }),
              let target = albums.first(where: { $0.id == targetId }) else { return }

        print("\n=== 🔀 [Repository] 앨범 병합: \(target.name) → \(source.name) ===")

        for cluster in target.clusters {
            cluster.album = source
            source.clusters.append(cluster)
        }

        let existingPhotoIds = Set(source.photos.map { $0.localIdentifier })
        for photo in target.photos where !existingPhotoIds.contains(photo.localIdentifier) {
            source.photos.append(photo)
        }

        source.photoCount = source.photos.count
        source.isEdited = true

        context.delete(target)
        try context.save()
        print("✅ [Repository] 병합 완료 — \(source.name): \(source.photoCount)장\n")
    }

    // MARK: - 사진 제외

    public func excludePhoto(photoId: String, fromAlbumId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == fromAlbumId }) else { return }

        print("\n=== 🚫 [Repository] 사진 제외: \(photoId) from \(album.name) ===")

        for cluster in album.clusters {
            if cluster.faceEmbeddings.contains(where: { $0.photo?.localIdentifier == photoId }) {
                cluster.excludedPhotoIds.append(photoId)
            }
        }

        album.photos.removeAll { $0.localIdentifier == photoId }
        album.photoCount = album.photos.count
        album.isEdited = true

        try context.save()
        print("✅ [Repository] 사진 제외 완료\n")
    }

    // MARK: - 앨범 삭제 + 블랙리스트

    public func deleteAlbum(albumId: UUID) async throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let album = albums.first(where: { $0.id == albumId }) else { return }

        print("\n=== 🗑️ [Repository] 앨범 삭제: \(album.name) ===")

        for cluster in album.clusters {
            let ids = cluster.faceEmbeddings.map { $0.id }
            guard !ids.isEmpty else { continue }
            let blacklist = ClusterBlacklistEntity(embeddingIds: ids)
            context.insert(blacklist)
        }

        context.delete(album)
        try context.save()
        print("✅ [Repository] 앨범 삭제 완료\n")
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
