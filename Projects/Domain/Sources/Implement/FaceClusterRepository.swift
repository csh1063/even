//
//  FaceClusterRepository.swift
//  Domain
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol FaceClusterRepository {
    /// 전체 재클러스터링 및 앨범 저장
    func clusterAndSaveAlbums() async throws

    /// 새 임베딩을 기존 클러스터에 매칭하여 앨범에 추가
    func matchAndAddNewEmbeddings(embeddingIds: [UUID]) async throws

    /// 앨범 병합 — source가 target을 흡수, source 유지
    func mergeAlbums(sourceId: UUID, targetId: UUID) async throws

    /// 사진을 앨범에서 제외
    func excludePhoto(photoId: String, fromAlbumId: UUID) async throws

    /// 앨범 삭제 + 블랙리스트 등록
    func deleteAlbum(albumId: UUID) async throws
}
