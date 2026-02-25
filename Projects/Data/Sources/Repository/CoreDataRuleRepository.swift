//
//  CoreDataRuleRepository.swift
//  Data
//
//  Created by sanghyeon on 2/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreData
import Domain

public final class CoreDataRuleRepository: RuleRepository {

    private let coreDataStack: CoreDataStack

    public init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Create

    public func create(
        folderID: UUID,
        type: RuleType,
        comparison: RuleComparison,
        value: String
    ) async throws -> Rule {

        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {

            // 1️⃣ FolderEntity fetch
            let folderRequest: NSFetchRequest<FolderEntity> = FolderEntity.fetchRequest()
            folderRequest.predicate = NSPredicate(format: "id == %@", folderID as CVarArg)
            folderRequest.fetchLimit = 1

            guard let folderEntity = try context.fetch(folderRequest).first else {
                throw NSError(domain: "FolderNotFound", code: 404)
            }

            // 2️⃣ RuleEntity 생성
            let entity = RuleEntity(context: context)
            entity.id = UUID()
            entity.type = type.rawValue
            entity.comparison = comparison.rawValue
            entity.value = value
            entity.folder = folderEntity

            try context.save()

            return entity.toDomain()
        }
    }

    // MARK: - Fetch

    public func fetchRules(folderID: UUID) async throws -> [Rule] {

        let context = coreDataStack.newBackgroundContext()

        return try await context.perform {

            let request: NSFetchRequest<RuleEntity> = RuleEntity.fetchRequest()
            request.predicate = NSPredicate(format: "folder.id == %@", folderID as CVarArg)

            let entities = try context.fetch(request)
            return entities.map { $0.toDomain() }
        }
    }

    // MARK: - Delete

    public func delete(ruleID: UUID) async throws {

        let context = coreDataStack.newBackgroundContext()

        try await context.perform {

            let request: NSFetchRequest<RuleEntity> = RuleEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", ruleID as CVarArg)
            request.fetchLimit = 1

            if let entity = try context.fetch(request).first {
                context.delete(entity)
                try context.save()
            }
        }
    }
}
