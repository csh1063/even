//
//  AnimalClusterRepository.swift
//  Domain
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//  FaceClusterRepository를 그대로 미러링한다 — 대상이 FaceEmbeddingEntity/ClusterEntity가 아니라
//  AnimalEmbeddingEntity/AnimalClusterEntity라는 점만 다르고 지원하는 동작(전체 재클러스터링,
//  병합/분리/제외/삭제, 유사도순 후보 조회)은 사람 얼굴과 동일하다. FaceClusterSummary/AlbumMergeCandidate는
//  이미 종에 무관한 형태라 그대로 재사용한다.
//

import Foundation

public protocol AnimalClusterRepository {
    /// 전체 재클러스터링 및 앨범 저장
    func clusterAndSaveAlbums(onProgress: @escaping @Sendable (Double) -> Void) async throws

    /// 새 임베딩을 기존 클러스터에 매칭하여 앨범에 추가
    func matchAndAddNewEmbeddings(embeddingIds: [UUID]) async throws

    /// 앨범 병합 — source가 target을 흡수, source 유지
    func mergeAlbums(sourceId: UUID, targetId: UUID) async throws

    /// 사진을 앨범에서 제외
    func excludePhoto(photoId: String, fromAlbumId: UUID) async throws

    /// 앨범 삭제 + 블랙리스트 등록
    func deleteAlbum(albumId: UUID) async throws

    /// 이 앨범을 구성하는 클러스터 목록 조회 — 앨범 분리 화면에서 사용
    func fetchClusters(albumId: UUID) async throws -> [FaceClusterSummary]

    /// 지정한 클러스터들을 앨범에서 떼어내 새 앨범으로 분리 (병합을 되돌릴 때 사용)
    func splitAlbum(albumId: UUID, clusterIds: [UUID]) async throws

    /// 다른 동물 앨범들을 이 앨범과의 centroid 유사도가 높은 순으로 정렬해 반환 — 합치기 후보 추천용
    func fetchOtherAnimalAlbumsSortedBySimilarity(excluding albumId: UUID) async throws -> [AlbumMergeCandidate]

    /// 주어진 사진들에 등장하는 동물이 속한 동물 앨범 id들 (중복 제거) — 여행 앨범에 사진 추가 시 반려동물 자동 연결용
    func fetchAnimalAlbumIds(forPhotoIds photoIds: [String]) async throws -> [UUID]
}
