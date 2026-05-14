//
//  MoaSchemaMigrationPlan.swift
//  Data
//
//  Created by sanghyeon on 5/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData

public enum MoaSchemaMigrationPlan: SchemaMigrationPlan {
    public static let schemas: [any VersionedSchema.Type] = [
        MoaSchemaV0.self
    ]
    public static let stages: [MigrationStage] = []
}

// 마이그레이션 예시
//enum MoaSchemaMigrationPlan: SchemaMigrationPlan {
//    static let schemas: [any VersionedSchema.Type] = [
//        MoaSchemaV1.self,
//        MoaSchemaV2.self
//    ]
//    static let stages: [MigrationStage] = [stage_v1_to_v2]
//    
//    static let stage_v1_to_v2 = MigrationStage.custom(
//        fromVersion: MoaSchemaV1.self,
//        toVersion: MoaSchemaV2.self,
//        willMigrate: nil,
//        didMigrate: { context in
//            let folders = try context.fetch(FetchDescriptor<FolderEntity>())
//            for folder in folders {
//                folder.from = ""
//            }
//            try context.save()
//        }
//    )
//}
