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
            createdAt: photo.createdAt,
            latitude: photo.latitude,
            longitude: photo.longitude,
            address: photo.address,
            addressEn: photo.addressEn,
            year: photo.year,
            month: photo.month
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
                
                if let latitude = photo.latitude { entity.latitude = latitude }
                if let longitude = photo.longitude { entity.longitude = longitude }
                if let address = photo.address { entity.address = address }
                if let addressEn = photo.addressEn { entity.addressEn = addressEn }
                if let year = photo.year { entity.year = year }
                if let month = photo.month { entity.month = month }
            } else {
                entity = PhotoEntity(
                    id: photo.id,
                    localIdentifier: photo.localIdentifier,
                    createdAt: photo.createdAt,
                    latitude: photo.latitude,
                    longitude: photo.longitude,
                    address: photo.address,
                    addressEn: photo.addressEn,
                    year: photo.year,
                    month: photo.month
                )
                context.insert(entity)
            }
            
            if labels.count > 0 {
                entity.labels.forEach { context.delete($0) }
                
                labels.forEach {
                    let labelEntity = PhotoLabelEntity(
                        name: $0.name,
                        confidence: $0.confidence,
                        photo: entity
                    )
                    context.insert(labelEntity)
                }
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
        print("keyword 삭제")
        let keywords = try context.fetch(FetchDescriptor<FolderKeywordEntity>())
        keywords.forEach { context.delete($0) }
        try context.save()
        
        print("label 삭제")
        let labels = try context.fetch(FetchDescriptor<PhotoLabelEntity>())
        labels.forEach { context.delete($0) }
        try context.save()
        
        print("photo-folder 연결 제거")
        let photos = try context.fetch(FetchDescriptor<PhotoEntity>())
        photos.forEach { $0.folders = [] }
        try context.save()
        
        print("folder 삭제")
        let folders = try context.fetch(FetchDescriptor<FolderEntity>())
        folders.forEach { context.delete($0) }
        try context.save()
        
        print("photo 삭제")
        photos.forEach { context.delete($0) }
        try context.save()
    }
}
