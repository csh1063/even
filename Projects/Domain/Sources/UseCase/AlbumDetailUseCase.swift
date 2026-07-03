//
//  AlbumDetailUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol AlbumDetailUseCase {
    func fetchPhotos(by albumId: UUID) async throws -> [Photo]
    func fetchFaceBoundingBoxes(clusterId: String) async throws -> [String: CGRect]
    func editAlbumName(new name: String, id: UUID) async throws
    func deleteAlbum(_ id: UUID) async throws
    func deletePhotos(_ photoIds: [String], albumId: UUID, deleteInLibrary: Bool) async throws
}

public final class DefaultAlbumDetailUseCase: AlbumDetailUseCase {

    private let repository: AlbumDataRepository
    private let libraryRepository: PhotoLibraryRepository

    public init(repository: AlbumDataRepository,
                libraryRepository: PhotoLibraryRepository) {
        self.repository = repository
        self.libraryRepository = libraryRepository
    }

    public func fetchPhotos(by albumId: UUID) async throws -> [Photo] {
        try repository.fetchPhotos(by: albumId)
    }

    public func fetchFaceBoundingBoxes(clusterId: String) async throws -> [String: CGRect] {
        try repository.fetchFaceBoundingBoxes(clusterId: clusterId)
    }

    public func editAlbumName(new name: String, id: UUID) async throws {
        try repository.updateAlbumName(new: name, id: id)
    }

    public func deleteAlbum(_ id: UUID) async throws {
        try repository.delete(id: id)
    }

    public func deletePhotos(_ photoIds: [String], albumId: UUID, deleteInLibrary: Bool) async throws {
        if deleteInLibrary {
            try await libraryRepository.deletePhotos(by: photoIds)
        }
        try repository.deletePhotos(albumId: albumId, photoIdentifiers: photoIds)
    }
}
