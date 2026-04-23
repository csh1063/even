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
    func saveAndUpdateLabels(photo: Photo, labels: [PhotoLabel]) async throws
    func fetchPhotos() throws -> [Photo]
    func fetchAll(page: Int, pageSize: Int) throws -> [Photo]
    func fetchPhotoCount() throws -> Int
    func fetchIds(page: Int, pageSize: Int) throws -> [String]
    func fetchAnalyzed() throws -> [String]
    func fetchLocationUnanalyzed() throws -> [Photo]
    func fetchUnanalyzed() throws -> [Photo]
    func fetchSyncPhotoId(byFolder localIdentifier: UUID) throws -> String?
    func fetchSyncPhotoCount(byFolder localIdentifier: UUID) throws -> Int
    func delete(identifier: String) throws
    func deleteAll() throws
}

extension PhotoDataRepository {
    func fetchAll(page: Int = -1, pageSize: Int = 50) throws -> [Photo] {
        return try fetchAll(page: page, pageSize: pageSize)
    }
}
