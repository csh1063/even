//
//  SimilarPhotoClusterRepository.swift
//  Domain
//
//  Created by sanghyeon on 6/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public protocol SimilarPhotoClusterRepository {
    func clusterAndSaveAlbums(photos: [Photo], existingAlbums: [Album]) async throws
}
