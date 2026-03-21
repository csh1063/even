//
//  DefaultFolderDataRepository.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import SwiftData
import Domain

public final class DefaultFolderDataRepository: FolderDataRepository {
    
    private let context: ModelContext
    
    public init(context: ModelContext) {
        self.context = context
    }
    
    public func saveFolder(folder: Folder) throws {
        let id = folder.id
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        let existing = try context.fetch(fetchDescriptor)
        guard existing.isEmpty else { return }
        
        let entity = FolderEntity(
            id: folder.id,
            name: folder.name,
            isAuto: folder.isAuto,
            coverPhotoIdentifier: folder.coverPhotoIdentifier
        )
        
        folder.keywords.forEach {
            let keywordEntity = FolderKeywordEntity(
                keyword: $0,
                weight: 1.0,
                folder: entity
            )
            context.insert(keywordEntity)
        }
        
        context.insert(entity)
        try context.save()
    }
    
    public func fetchAll() throws -> [Folder] {
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }
    
    public func updateFolder(folder: Folder) throws {
        let id = folder.id
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let entity = try context.fetch(fetchDescriptor).first else {
            throw FolderRepositoryError.folderNotFound
        }
        
        entity.name = folder.name
        entity.coverPhotoIdentifier = folder.coverPhotoIdentifier
        
        entity.keywords.forEach { context.delete($0) }
        folder.keywords.forEach {
            let keywordEntity = FolderKeywordEntity(
                keyword: $0,
                weight: 1.0,
                folder: entity
            )
            context.insert(keywordEntity)
        }
        
        try context.save()
    }
    
    public func delete(id: UUID) throws {
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let entity = try context.fetch(fetchDescriptor).first else {
            throw FolderRepositoryError.folderNotFound
        }
        
        context.delete(entity)
        try context.save()
    }
    
    public func addPhoto(folderId: UUID, photoIdentifier: String) throws {
        let folderDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.id == folderId }
        )
        let photoDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.localIdentifier == photoIdentifier }
        )
        
        guard let folder = try context.fetch(folderDescriptor).first else {
            throw FolderRepositoryError.folderNotFound
        }
        guard let photo = try context.fetch(photoDescriptor).first else {
            throw FolderRepositoryError.photoNotFound
        }
        
        let map = FolderPhotoMapEntity(
            folder: folder,
            photo: photo
        )
        context.insert(map)
        try context.save()
    }
    
    public func removePhoto(folderId: UUID, photoIdentifier: String) throws {
        let fetchDescriptor = FetchDescriptor<FolderPhotoMapEntity>(
            predicate: #Predicate {
                $0.folder?.id == folderId &&
                $0.photo?.localIdentifier == photoIdentifier
            }
        )
        
        guard let map = try context.fetch(fetchDescriptor).first else { return }
        context.delete(map)
        try context.save()
    }
}
