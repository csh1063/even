//
//  PhotoLibraryUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoLibraryUseCase {
    func fetchData(page: Int) async throws -> PhotoList
    func checkPermission() async throws -> PhotoPermission
    func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T>
}

public class DefaultPhotoLibraryUseCase: PhotoLibraryUseCase {
    
    let repository: PhotoLibraryRepository
    
    public init(repository: PhotoLibraryRepository) {
        self.repository = repository
    }
    
    public func fetchData(page: Int) async throws -> PhotoList {
        try await self.repository.fetchPhotos(page: page)
    }
    
    public func checkPermission() async throws -> PhotoPermission {
        try await self.repository.checkPermission()
    }
    
    public func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T> {
        return try await self.repository.loadImage(id: id, type: type)
    }
}
