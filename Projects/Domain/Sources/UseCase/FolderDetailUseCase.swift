//
//  FolderDetailUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol FolderDetailUseCase {
    func fetchPhotos(by folderId: UUID) async throws -> [Photo]
    func editFolderName(new name: String, id: UUID) async throws
}

public final class DefaultFolderDetailUseCase: FolderDetailUseCase {
    
    private let repository: FolderDataRepository
    
    public init(repository: FolderDataRepository) {
        self.repository = repository
    }
    
    public func fetchPhotos(by folderId: UUID) async throws -> [Photo] {
        try repository.fetchPhotos(by: folderId)
    }
    
    public func editFolderName(new name: String, id: UUID) async throws {
        try repository.updateFolderName(new: name, id: id)
    }
}
