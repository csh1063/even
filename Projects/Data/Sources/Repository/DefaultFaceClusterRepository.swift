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

    public func clusterAndSaveFolders() async throws {
        print("\n=== 🚀 [Repository] 클러스터링 및 폴더 저장 프로세스 시작 ===")
        let context = ModelContext(container)
        
        // 1. DB에서 모든 FaceEmbeddingEntity 로드
        let embeddingDescriptor = FetchDescriptor<FaceEmbeddingEntity>()
        let allEntities = try context.fetch(embeddingDescriptor)
        print("📦 [Repository] DB에서 총 \(allEntities.count)개의 임베딩 엔티티를 로드했습니다.")
        
        guard !allEntities.isEmpty else {
            print("⚠️ [Repository] 처리할 임베딩 데이터가 없어 종료합니다.")
            return
        }

        // 2. 기존에 이미 생성된 인물 폴더들 미리 로드
        let existingFolders = try context.fetch(FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.from == "face" }
        ))
        print("📁 [Repository] 기존에 존재하는 인물 폴더 수: \(existingFolders.count)개")
        
        // 3. 도메인 모델로 변환 후 클러스터링 서비스 호출
        let embeddings = allEntities.map { $0.toDomain() }
        let clusteredResults = clusterService.cluster(embeddings: embeddings)
        
        // 4. clusterId별로 그룹핑
        let groups = Dictionary(grouping: clusteredResults, by: { $0.1 })
        print("\n📊 [Repository] 서비스 연산 완료 -> 총 \(groups.count)개의 인물 그룹 분리됨. DB 반영 시작...")
        
        // 5. 각 그룹별로 폴더 매핑 및 사진 연결
        for (clusterId, pairs) in groups {
            guard pairs.count >= 3 else {
                print("⏭️ [Repository] [\(clusterId)] 사진 \(pairs.count)장 미만 -> 스킵")
                continue
            }
            
            let folderName = clusterId
            let folder: FolderEntity
            
            // 기존 폴더가 있으면 재사용, 없으면 신규 생성
            if let existingFolder = existingFolders.first(where: { $0.name == folderName }) {
                folder = existingFolder
                print("🔄 [Repository] [\(clusterId)] 기존 폴더 활용")
            } else {
                folder = FolderEntity(
                    id: UUID(),
                    name: folderName,
                    displayName: folderName,
                    isAuto: true,
                    coverPhotoIdentifier: nil,
                    from: "face"
                )
                context.insert(folder)
                print("✨ [Repository] [\(clusterId)] 신규 폴더 생성 및 켄텍스트 삽입")
            }

            let embeddingIds = Set(pairs.map { $0.0.id })
            let matchedEntities = allEntities.filter { embeddingIds.contains($0.id) }

            // 중복 체크 속도 최적화를 위해 현재 폴더 내 사진 ID들을 Set으로 빌드
            var currentPhotoIds = Set(folder.photos.map { $0.localIdentifier })
            var newlyAddedCount = 0

            for entity in matchedEntities {
                entity.clusterId = clusterId
                
                guard let photo = entity.photo else { continue }
                
                // O(1) 고속 중복 체크
                if !currentPhotoIds.contains(photo.localIdentifier) {
                    folder.photos.append(photo)
                    currentPhotoIds.insert(photo.localIdentifier)
                    newlyAddedCount += 1
                }
            }

            // 폴더 메타데이터 갱신
            folder.photoCount = folder.photos.count
            folder.coverPhotoIdentifier = folder.photos.sorted { $0.createdAt > $1.createdAt }.first?.localIdentifier
            
            print("📝 [Repository] [\(clusterId)] 매핑 완료 (새로 추가된 사진: \(newlyAddedCount)장 / 총 사진: \(folder.photoCount)장)")
        }

        // 6. 최종 저장
        print("💾 [Repository] 변경 사항을 SwiftData에 저장합니다...")
        try context.save()
        print("✅ [Repository] 모든 데이터 영속화 성공!\n")
    }
}

//public final class DefaultFaceClusterRepository: FaceClusterRepository {
//
//    private let container: ModelContainer
//    private let clusterService: FaceClusterService
//
//    public init(container: ModelContainer, clusterService: FaceClusterService) {
//        self.container = container
//        self.clusterService = clusterService
//    }
//
//    public func clusterAndSaveFolders() async throws {
//        let context = ModelContext(container)
//
//        // 1. people 라벨 가진 사진의 FaceEmbedding 전부 로드
//        let fetchDescriptor = FetchDescriptor<FaceEmbeddingEntity>()
//        let entities = try context.fetch(fetchDescriptor)
//        print("entities:", entities.count)
//        guard !entities.isEmpty else { return }
//
//        let embeddings = entities.map { $0.toDomain() }
//
//        // 2. 클러스터링
//        let clustered = clusterService.cluster(embeddings: embeddings)
//
//        // 3. clusterId별로 그룹핑
//        let groups = Dictionary(grouping: clustered, by: { $0.1 })
//        
//        print("groups.count:", groups.count)
//        // 4. 사람 폴더 생성 및 사진 연결
//        for (clusterId, pairs) in groups {
//            print("clusterId:", clusterId)
//            // 폴더 생성
//            let folderName = clusterId  // ex) "사람 1"
//            let folderDescriptor = FetchDescriptor<FolderEntity>(
//                predicate: #Predicate { $0.name == folderName }
//            )
//            let existing = try context.fetch(folderDescriptor)
//
//            let folder: FolderEntity
//            if let existingFolder = existing.first {
//                folder = existingFolder
//            } else {
//                let newFolder = FolderEntity(
//                    id: UUID(),
//                    name: folderName,
//                    displayName: folderName,
//                    isAuto: true,
//                    coverPhotoIdentifier: nil,
//                    from: "face"
//                )
//                context.insert(newFolder)
//                folder = newFolder
//            }
//
//            // 5. FaceEmbeddingEntity의 clusterId 업데이트 + 사진 연결
//            let embeddingIds = Set(pairs.map { $0.0.id })
//            let matchedEntities = entities.filter { embeddingIds.contains($0.id) }
//
//            for entity in matchedEntities {
//                entity.clusterId = clusterId
//
//                guard let photo = entity.photo else { continue }
//                guard !folder.photos.contains(where: { $0.localIdentifier == photo.localIdentifier }) else { continue }
//                folder.photos.append(photo)
//            }
//
//            folder.photoCount = folder.photos.count
//            folder.coverPhotoIdentifier = folder.photos.sorted {
//                $0.createdAt > $1.createdAt
//            }.first?.localIdentifier
//        }
//
//        try context.save()
//    }
//}
