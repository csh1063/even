//
//  DefaultFaceClusterRepository.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import SwiftData
import Domain

public final class DefaultFaceClusterRepository: FaceClusterRepository {
    private let container: ModelContainer
    private let clusterService: FaceClusterService

    public init(container: ModelContainer, clusterService: FaceClusterService) {
        self.container = container
        self.clusterService = clusterService
    }

    public func clusterAndSaveAlbums() async throws {
        print("\n=== 🚀 [Repository] 클러스터링 및 앨범 저장 프로세스 시작 ===")
        let context = ModelContext(container)

        // 1. DB에서 모든 FaceEmbeddingEntity 로드
        let embeddingDescriptor = FetchDescriptor<FaceEmbeddingEntity>(
            predicate: #Predicate { $0.hasGlasses == false }
        )
        let allEntities = try context.fetch(embeddingDescriptor)

        print("📦 [Repository] DB에서 총 \(allEntities.count)개의 임베딩 엔티티를 로드했습니다.")

        guard !allEntities.isEmpty else {
            print("⚠️ [Repository] 처리할 임베딩 데이터가 없어 종료합니다.")
            return
        }

        // 2. 기존에 이미 생성된 인물 앨범들 미리 로드
        let existingAlbums = try context.fetch(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "face" }
        ))
        print("📁 [Repository] 기존에 존재하는 인물 앨범 수: \(existingAlbums.count)개")

        // 3. 도메인 모델로 변환 후 클러스터링 서비스 호출
        let embeddings = Array(allEntities.map { $0.toDomain() }.reversed())
        let clusteredResults = clusterService.cluster(embeddings: embeddings)

        // 4. clusterId별로 그룹핑
        let groups = Dictionary(grouping: clusteredResults, by: { $0.1 })
        print("\n📊 [Repository] 서비스 연산 완료 -> 총 \(groups.count)개의 인물 그룹 분리됨. DB 반영 시작...")

        // 5. 각 그룹별로 앨범 매핑 및 사진 연결
        for (clusterId, pairs) in groups {
            guard pairs.count >= 3 else {
                print("⏭️ [Repository] [\(clusterId)] 사진 \(pairs.count)장 미만 -> 스킵")
                continue
            }

            let albumName = clusterId
            let album: AlbumEntity

            // 기존 앨범가 있으면 재사용, 없으면 신규 생성
            if let existingAlbum = existingAlbums.first(where: { $0.name == albumName }) {
                album = existingAlbum
                print("🔄 [Repository] [\(clusterId)] 기존 앨범 활용")
            } else {
                album = AlbumEntity(
                    id: UUID(),
                    name: albumName,
                    displayName: albumName,
                    isAuto: true,
                    coverPhotoIdentifier: nil,
                    from: "face"
                )
                context.insert(album)
                print("✨ [Repository] [\(clusterId)] 신규 앨범 생성 및 켄텍스트 삽입")
            }

            let embeddingIds = Set(pairs.map { $0.0.id })
            let matchedEntities = allEntities.filter { embeddingIds.contains($0.id) }

            // 중복 체크 속도 최적화를 위해 현재 앨범 내 사진 ID들을 Set으로 빌드
            var currentPhotoIds = Set(album.photos.map { $0.localIdentifier })
            var newlyAddedCount = 0

            for entity in matchedEntities {
                entity.clusterId = clusterId

                guard let photo = entity.photo else { continue }

                // O(1) 고속 중복 체크
                if !currentPhotoIds.contains(photo.localIdentifier) && photo.faceEmbeddings.count <= 4 {
                    album.photos.append(photo)
                    currentPhotoIds.insert(photo.localIdentifier)
                    newlyAddedCount += 1
                }
            }

            // 앨범 메타데이터 갱신
            album.photoCount = album.photos.count
            album.coverPhotoIdentifier = album.photos.sorted { $0.createdAt > $1.createdAt }.first?.localIdentifier

            print("📝 [Repository] [\(clusterId)] 매핑 완료 (새로 추가된 사진: \(newlyAddedCount)장 / 총 사진: \(album.photoCount)장)")
        }

        // 6. 최종 저장
        print("💾 [Repository] 변경 사항을 SwiftData에 저장합니다...")
        try context.save()
        print("✅ [Repository] 모든 데이터 영속화 성공!\n")
    }
}
