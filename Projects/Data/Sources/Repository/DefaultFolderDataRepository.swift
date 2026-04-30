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
import Combine

public final class DefaultFolderDataRepository: FolderDataRepository {
    
    private let container: ModelContainer
    
    private let foldersSubject = CurrentValueSubject<[Folder], Never>([])
    public var foldersPublisher: AnyPublisher<[Folder], Never> {
        foldersSubject.eraseToAnyPublisher()
    }
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func saveFolder(folder: Folder) throws -> Folder? {
        
        let context = ModelContext(container)
        
        let name = folder.name
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.name == name }
        )
        
        let existing = try context.fetch(fetchDescriptor)
        guard existing.isEmpty else { return nil }
        
        let entity = FolderEntity(
            id: folder.id,
            name: folder.name,
            displayName: folder.displayName,
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
        return folder
    }
    
    public func fetchAll() throws -> [Folder] {
        
        let context = ModelContext(container)
        
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            sortBy: [SortDescriptor(\.photoCount, order: .reverse),
                     SortDescriptor(\.displayName, order: .forward)]
        )
        return try context.fetch(fetchDescriptor).map {$0.toDomain()}
    }
    
    public func fetchAutoAll() throws -> [Folder] {
        
        let context = ModelContext(container)
        
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.isAuto == true }
        )
        return try context.fetch(fetchDescriptor).map {$0.toDomainWithKey()}
    }
    
    public func fetchPhotos(by folderId: UUID) throws -> [Photo] {
        
        let context = ModelContext(container)
        let photoFetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { photo in
                photo.folders.contains { $0.id == folderId }
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let photos = try context.fetch(photoFetchDescriptor)
        return photos.map { $0.toDomain() }
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
        entity.displayName = folder.displayName
        entity.coverPhotoIdentifier = folder.coverPhotoIdentifier
        entity.photoCount = folder.photoCount
        
        try context.save()
    }
    
    public func updateFolderName(new name: String, id: UUID) throws {
        
        let context = ModelContext(container)
        
        let fetchDescriptor = FetchDescriptor<FolderEntity>(
            predicate: #Predicate { $0.id == id }
        )
        
        guard let entity = try context.fetch(fetchDescriptor).first else {
            throw FolderRepositoryError.folderNotFound
        }
        
        entity.displayName = name
        
        try context.save()
        
        let updated = try fetchAll()
        foldersSubject.send(updated)
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
        
        let updated = try fetchAll()
        foldersSubject.send(updated)
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
        
        let existingIds = Set(folder.photos.map { $0.localIdentifier })
        let uniqueNewPhotos = photos.filter { !existingIds.contains($0.localIdentifier) }
        
        folder.photos.append(contentsOf: uniqueNewPhotos)
        folder.photoCount = folder.photos.count
        folder.coverPhotoIdentifier = folder.photos.sorted {
            $0.createdAt > $1.createdAt
        }.first?.localIdentifier
        
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
    
    public func syncPhotoCount() throws {
        let context = ModelContext(container)
        
        let folderDescriptor = FetchDescriptor<FolderEntity>()
        let folders = try context.fetch(folderDescriptor)
        
        folders.forEach { folder in
            folder.photoCount = folder.photos.count
        }
        
        try context.save()
    }
}
