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

    public func fetchPhotoCount() async throws -> Int {
        return try await self.libraryService.getPhotoCount()
    }

    public func fetchPhotos(page: Int, pageCount: Int) async throws -> PhotoList {
        return try await self.libraryService.getPhotoList(page: page, pageCount: pageCount).toDomain()
    }

    public func fetchPhotoIds() async throws -> [String] {
        return try await self.libraryService.getPhotoIds()
    }

    public func checkPermission() async throws -> PhotoPermission {
        try await self.permissionService.checkPermission()
    }

    public func deletePhotos(by ids: [String]) async throws {
        try await self.libraryService.deletePhotos(localIdentifiers: ids)
    }

    public func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T> {
        let cgImage = try await self.libraryService.loadImage(id: id, type: type)
        return ImageData(cgImage: cgImage as? T)
    }

    public func fetchPhotos(before date: Date, page: Int, pageCount: Int) async throws -> PhotoList {
        try await self.libraryService.getPhotosBefore(date, page: page, pageCount: pageCount).toDomain()
    }

    public func fetchPhotos(after date: Date, page: Int, pageCount: Int) async throws -> PhotoList {
        try await self.libraryService.getPhotosAfter(date, page: page, pageCount: pageCount).toDomain()
    }
}
