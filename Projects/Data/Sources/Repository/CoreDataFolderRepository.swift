//
//  CoreDataFolderRepository.swift
//  Data
//
//  Created by sanghyeon on 2/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreData
import Domain

public final class CoreDataFolderRepository: FolderRepository {

    private let coreDataStack: CoreDataStack

    public init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Create

    public func create(name: String) async throws -> Folder {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {

            let entity = FolderEntity(context: context)
            entity.id = UUID()
            entity.name = name

            try context.save()

            return entity.toDomain()
        }
    }

    // MARK: - Fetch All

    public func fetchAll() async throws -> [Folder] {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {

            let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(key: "name", ascending: true)
            ]

            let entities = try context.fetch(request)
            return entities.map { $0.toDomain() }
        }
    }
    
    // MARK: - Fetch Paging
    
    public func fetchPage(offset: Int, limit: Int) async throws -> [Folder] {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {

            let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(key: "name", ascending: true)
            ]
            request.fetchOffset = offset
            request.fetchLimit = limit

            let entities = try context.fetch(request)
            return entities.map { $0.toDomain() }
        }
    }

    // MARK: - Fetch Single

    public func fetch(id: UUID) async throws -> Folder? {
        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {

            let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            return try context.fetch(request).first?.toDomain()
        }
    }

    // MARK: - Update

    public func update(id: UUID, name: String) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {

            let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            guard let entity = try context.fetch(request).first else { return }

            entity.name = name

            try context.save()
        }
    }

    // MARK: - Delete

    public func delete(folderID: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()

        try await context.perform {

            let request: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", folderID as CVarArg)
            request.fetchLimit = 1

            guard let entity = try context.fetch(request).first else { return }

            context.delete(entity)
            try context.save()
        }
    }
}
