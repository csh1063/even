//
//  PhotoDataRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoDataRepository {
    func savePhoto(photo: Photo) throws
    func saveAllPhotosBase(_ photos: [Photo]) throws
    func saveAndUpdateLabels(photo: Photo, labels: [PhotoLabel]) async throws
    func fetchPhotos(page: Int, pageSize: Int) throws -> [Photo]
    func fetchAll(page: Int, pageSize: Int) throws -> [Photo]
    func fetchPhotoCount() throws -> Int
    func fetchIds(page: Int, pageSize: Int) throws -> [String]
    func fetchHasCoordinators() throws -> [Photo]
    func fetchAnalyzed() throws -> [String]
    func fetchLocationUnanalyzed() throws -> [Photo]
    func fetchUnanalyzed() throws -> [Photo]
    func fetchAlbumUnclassified(limit: Int) throws -> [Photo]
    func markAlbumsGenerated(identifiers: [String]) throws
    func fetchSimilarUnchecked() throws -> [Photo]
    func markSimilarChecked(identifiers: [String]) throws
    func fetchSyncPhotoId(byAlbum localIdentifier: UUID) throws -> String?
    func fetchSyncPhotoCount(byAlbum localIdentifier: UUID) throws -> Int
    func delete(identifier: String) throws
}

extension PhotoDataRepository {
    func fetchAll(page: Int = -1, pageSize: Int = 50) throws -> [Photo] {
        return try fetchAll(page: page, pageSize: pageSize)
    }

    func fetchPhotos(page: Int = -1, pageSize: Int = 300) throws -> [Photo] {
        return try fetchPhotos(page: page, pageSize: pageSize)
    }
}
