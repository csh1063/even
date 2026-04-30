//
//  PhotoLibraryRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoLibraryRepository {
    func fetchPhotos(page: Int) async throws -> PhotoList
    func fetchPhotoIds() async throws -> [String]
    func checkPermission() async throws -> PhotoPermission
    func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T>
}

extension PhotoLibraryRepository {
    func fetchPhotos(page: Int = 0) async throws -> PhotoList {
        try await fetchPhotos(page: page)
    }
}
