//
//  DefaultDataPhotoRepository.swift
//  Data
//
//  Created by sanghyeon on 2/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreData
import Domain

public final class DefaultDataPhotoRepository: DataPhotoRepository {
    public func fetchAll() async throws -> [Domain.Photo] {
        return []
    }
    
    public func fetch(page: Int, pageSize: Int) async throws -> [Domain.Photo] {
        return []
    }
    
    public func create(_ photo: Domain.Photo) async throws {
        
    }
    
    public func update(_ photo: Domain.Photo) async throws {
        
    }
    
    public func delete(_ photo: Domain.Photo) async throws {
        
    }
    

    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

//    public func fetchAll() async throws -> [Photo] {
//        try await context.perform { [weak self] in
//            guard let self else {return []}
//            let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
//            let entities = try self.context.fetch(request)
//            return entities.map { $0.toDomain() }
//        }
//    }
//
//    public func fetch(page: Int, pageSize: Int) async throws -> [Photo] {
//        try await context.perform { [weak self] in
//            guard let self else {return []}
//            let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
//            request.fetchOffset = page * pageSize
//            request.fetchLimit = pageSize
//            let entities = try self.context.fetch(request)
//            return entities.map { $0.toDomain() }
//        }
//    }
//
//    public func create(_ photo: Photo) async throws {
//        try await context.perform { [weak self] in
//            guard let self else {return}
//            let entity = PhotoEntity(context: self.context)
//            entity.update(from: photo)
//            try self.context.save()
//        }
//    }
//
//    public func update(_ photo: Photo) async throws {
//        try await context.perform { [weak self] in
//            guard let self else {return}
//            let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
//            request.predicate = NSPredicate(format: "id == %@", photo.id as CVarArg)
//            if let entity = try self.context.fetch(request).first {
//                entity.update(from: photo)
//                try self.context.save()
//            }
//        }
//    }
//
//    public func delete(_ photo: Photo) async throws {
//        try await context.perform { [weak self] in
//            guard let self else {return}
//            let request: NSFetchRequest<PhotoEntity> = PhotoEntity.fetchRequest()
//            request.predicate = NSPredicate(format: "id == %@", photo.id as CVarArg)
//            if let entity = try self.context.fetch(request).first {
//                self.context.delete(entity)
//                try self.context.save()
//            }
//        }
//    }
}
