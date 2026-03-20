//
//  DefaultPhotoLibraryRepository.swift
//  Data
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

public final class DefaultPhotoLibraryRepository: PhotoLibraryRepository {

    private let libraryService: PhotoLibraryService
    private let permissionService: PermissionService
    
    public init(
        libraryService: PhotoLibraryService,
        permissionService: PermissionService
    ) {
        self.libraryService = libraryService
        self.permissionService = permissionService
    }

    public func fetchPhotos(page: Int) async throws -> PhotoList {
        return try await self.libraryService.getPhotoList(page: page).toDomain()
    }
    
    public func checkPermission() async throws -> PhotoPermission {
        try await self.permissionService.checkPermission()
    }
    
    public func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T> {
        let cgImage = try await self.libraryService.loadImage(id: id, type: type)
        return ImageData(cgImage: cgImage as? T)
    }
}

