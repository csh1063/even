//
//  SimilarPhotoClusterRepository.swift
//  Domain
//
//  Created by sanghyeon on 6/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public protocol SimilarPhotoClusterRepository {
    func clusterAndSaveAlbums(photos: [Photo], existingAlbums: [Album], onProgress: @escaping @Sendable (Double) -> Void) async throws

    /// 새로 추가된 사진(newPhotos)의 시간 윈도우 안에 드는 사진만 대상으로 비교하고,
    /// 기존 비슷한사진 앨범이 있으면 거기에 추가하고 없으면 새로 만든다. 기존 앨범을 삭제하지 않는다.
    /// - allPhotos: 시간 윈도우 이웃을 찾기 위한 전체 사진 목록 (라벨/벡터 불필요, id+createdAt이면 충분)
    func clusterNewPhotos(
        newPhotos: [Photo],
        allPhotos: [Photo],
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws
}
