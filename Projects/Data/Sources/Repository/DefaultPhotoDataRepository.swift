//
//  DefaultPhotoDataRepository.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation
import Domain

public final class DefaultPhotoDataRepository: PhotoDataRepository {
    
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func savePhoto(photo: Photo) throws {
        let context = ModelContext(container)
        let identifier = photo.localIdentifier
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.localIdentifier == identifier }
        )
        
        let existing = try context.fetch(fetchDescriptor)
        guard existing.isEmpty else { return }
        
        let entity = PhotoEntity(
            id: photo.id,
            localIdentifier: photo.localIdentifier,
            createdAt: photo.createdAt
        )
        context.insert(entity)
        try context.save()
    }
    
    public func saveAndUpdateLabels(photo: Photo, labels: [PhotoLabel]) async throws {
        try await Task.detached(priority: .high) { [container] in
            let context = ModelContext(container)
            
            let identifier = photo.localIdentifier
            let fetchDescriptor = FetchDescriptor<PhotoEntity>(
                predicate: #Predicate { $0.localIdentifier == identifier }
            )
            
            let entity: PhotoEntity
            if let existing = try context.fetch(fetchDescriptor).first {
                entity = existing
            } else {
                entity = PhotoEntity(
                    id: photo.id,
                    localIdentifier: photo.localIdentifier,
                    createdAt: photo.createdAt
                )
                context.insert(entity)
            }
            
            entity.labels.forEach { context.delete($0) }
            
            labels.forEach {
                let labelEntity = PhotoLabelEntity(
                    name: $0.name,
                    confidence: $0.confidence,
                    photo: entity
                )
                context.insert(labelEntity)
            }
            
            entity.analyzedAt = Date()
            try context.save()
        }.value
    }
    
    public func fetchAll() throws -> [Photo] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }
    
    public func fetchUnanalyzed() throws -> [Photo] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.analyzedAt == nil }
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }
    
    public func delete(identifier: String) throws {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.localIdentifier == identifier }
        )
        
        guard let entity = try context.fetch(fetchDescriptor).first else {
            throw PhotoRepositoryError.photoNotFound
        }
        
        context.delete(entity)
        try context.save()
    }
    
    public func deleteAll() throws {
        let context = ModelContext(container)
        // keyword 삭제
        let keywords = try context.fetch(FetchDescriptor<FolderKeywordEntity>())
        keywords.forEach { context.delete($0) }
        try context.save()
        
        // label 삭제
        let labels = try context.fetch(FetchDescriptor<PhotoLabelEntity>())
        labels.forEach { context.delete($0) }
        try context.save()
        
        // photo-folder 연결 제거
        let photos = try context.fetch(FetchDescriptor<PhotoEntity>())
        photos.forEach { $0.folders = [] }
        try context.save()
        
        // folder 삭제
        let folders = try context.fetch(FetchDescriptor<FolderEntity>())
        folders.forEach { context.delete($0) }
        try context.save()
        
        // photo 삭제
        photos.forEach { context.delete($0) }
        try context.save()
    }
}
