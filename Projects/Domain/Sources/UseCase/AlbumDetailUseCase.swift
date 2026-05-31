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
    func editAlbumName(new name: String, id: UUID) async throws
    func deleteAlbum(_ id: UUID) async throws
}

public final class DefaultAlbumDetailUseCase: AlbumDetailUseCase {
    
    private let repository: AlbumDataRepository
    
    public init(repository: AlbumDataRepository) {
        self.repository = repository
    }
    
    public func fetchPhotos(by albumId: UUID) async throws -> [Photo] {
        try repository.fetchPhotos(by: albumId)
    }
    
    public func editAlbumName(new name: String, id: UUID) async throws {
        try repository.updateAlbumName(new: name, id: id)
    }
    
    public func deleteAlbum(_ id: UUID) async throws {
        try repository.delete(id: id)
    }
}
