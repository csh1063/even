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
            isoCountryCode: photo.isoCountryCode,
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
                if let isoCountryCode = photo.isoCountryCode { entity.isoCountryCode = isoCountryCode }
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
                    isoCountryCode: photo.isoCountryCode,
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
    
    public func fetchPhotos() throws -> [Photo] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }
    
    public func fetchAll(page: Int = -1, pageSize: Int = 50) throws -> [Photo] {
        
        let context = ModelContext(container)
        
        var fetchDescriptor = FetchDescriptor<PhotoEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        if page >= 0 {
            fetchDescriptor.fetchLimit = pageSize
            fetchDescriptor.fetchOffset = page * pageSize
        }
        
        return try context.fetch(fetchDescriptor).map { $0.toDomainAll() }
    }
    
    public func fetchPhotoCount() throws -> Int {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>()
        return try context.fetchCount(fetchDescriptor)
    }
    
    public func fetchIds(page: Int, pageSize: Int) throws -> [String] {
        
        let context = ModelContext(container)
        
        var fetchDescriptor = FetchDescriptor<PhotoEntity>()
        
        if page >= 0 {
            fetchDescriptor.fetchLimit = pageSize
            fetchDescriptor.fetchOffset = page * pageSize
        }
        
        return try context.fetch(fetchDescriptor).map {$0.localIdentifier}
    }
    
    public func fetchAnalyzed() throws -> [String] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.analyzedAt != nil }
        )
        return try context.fetch(fetchDescriptor).map { $0.localIdentifier }
    }
    
    public func fetchLocationUnanalyzed() throws -> [Photo] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.analyzedAt != nil && $0.isoCountryCode == nil }
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }
    
    public func fetchSyncPhotoId(byFolder localIdentifier: UUID) throws -> String? {
        let context = ModelContext(container)
        var fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate<PhotoEntity> {
                $0.folders.contains { $0.id == localIdentifier }
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = 1
        
        guard let entity = try context.fetch(fetchDescriptor).first else {
            return nil
        }
        
        return entity.localIdentifier
    }
    
    public func fetchSyncPhotoCount(byFolder localIdentifier: UUID) throws -> Int {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate<PhotoEntity> {
                $0.folders.contains { $0.id == localIdentifier }
            }
        )
        return try context.fetchCount(fetchDescriptor)
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
        
        for folder in entity.folders where folder.coverPhotoIdentifier == identifier {
            let photos = folder.photos
                .filter { $0.localIdentifier != identifier }
                .sorted { $0.createdAt > $1.createdAt }
            folder.coverPhotoIdentifier = photos.first?.localIdentifier
            
            for folder in entity.folders {
                folder.photoCount = photos.count
            }
        }
        
        context.delete(entity)
        
        try context.save()
    }
    
    public func deleteAll() throws {
        let context = ModelContext(container)
        
        print("photo-folder 연결 제거")
        let folders = try context.fetch(FetchDescriptor<FolderEntity>())
        folders.forEach { $0.photos.removeAll() }
        try context.save()
        
        folders.forEach { context.delete($0) }
        try context.save()
        
        print("photo 삭제")
        try context.delete(model: PhotoEntity.self)
        try context.save()
    }
}
