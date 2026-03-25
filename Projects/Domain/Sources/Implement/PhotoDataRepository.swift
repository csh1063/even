//
//  PhotoDataRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public protocol PhotoDataRepository {
    func savePhoto(photo: Photo) throws
    func saveAndUpdateLabels(photo: Photo, labels: [PhotoLabel]) async throws
    func fetchAll() throws -> [Photo]
    func fetchUnanalyzed() throws -> [Photo]
    func delete(identifier: String) throws
    func deleteAll() throws
}
