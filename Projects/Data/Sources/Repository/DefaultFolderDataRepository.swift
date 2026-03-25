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
    
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func saveFolder(folder: Folder) throws {
        
        let context = ModelContext(container)
        
        let name = folder.name
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.name == name }
        )
        
        let existing = try context.fetch(fetchDescriptor)
        guard existing.isEmpty else { return }
        
        let entity = FolderEntity(
            id: folder.id,
            name: folder.name,
            displayName: folder.name,
            isAuto: folder.isAuto,
            coverPhotoIdentifier: folder.coverPhotoIdentifier
        )
        context.insert(entity)
        
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
    
    public func fetchAll() throws -> [Folder] {
        
        let context = ModelContext(container)
        
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            sortBy: [SortDescriptor(\.displayName, order: .forward)]
        )
        return try context.fetch(fetchDescriptor).sorted {
            $0.photos.count > $1.photos.count
        }.map {$0.toDomain()}
    }
    
    public func updateFolder(folder: Folder) throws {
        
        let context = ModelContext(container)
        
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
        
        let context = ModelContext(container)
        
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
        
        let context = ModelContext(container)
        
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
        // 중복 체크
        guard !folder.photos.contains(where: { $0.localIdentifier == photoIdentifier }) else { return }
        
        folder.photos.append(photo)
        
        try context.save()
    }
    
    public func addPhotos(folderId: UUID, photoIdentifiers: [String]) throws {
        
        let context = ModelContext(container)
        
        let folderDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.id == folderId }
        )
        guard let folder = try context.fetch(folderDescriptor).first else {
            throw FolderRepositoryError.folderNotFound
        }
        
        let ids = photoIdentifiers
        let photoDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { ids.contains($0.localIdentifier) }
        )
        
        let photos = try context.fetch(photoDescriptor)
        folder.photos = photos
        try context.save()
    }
    
    public func removePhoto(folderId: UUID, photoIdentifier: String) throws {
//        let fetchDescriptor = FetchDescriptor<FolderPhotoMapEntity>(
//            predicate: #Predicate {
//                $0.folder?.id == folderId &&
//                $0.photo?.localIdentifier == photoIdentifier
//            }
//        )
//        
//        guard let map = try context.fetch(fetchDescriptor).first else { return }
//        context.delete(map)
//        try context.save()
    }
    
    public func deleteAutoFolders() throws {
        
        let context = ModelContext(container)
        
        let folderDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.isAuto == true }
        )
        let autoFolders = try context.fetch(folderDescriptor)
        
        autoFolders.forEach { context.delete($0) }
        try context.save()
    }
}
