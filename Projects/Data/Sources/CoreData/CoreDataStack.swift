//
//  CoreDataStack.swift
//  Data
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreData

public final class CoreDataStack {

    public static let shared = CoreDataStack()

    public let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "Model")

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData load error: \(error)")
            }
        }

        // UI context 설정
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // 표준 Background Context 생성
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
}
