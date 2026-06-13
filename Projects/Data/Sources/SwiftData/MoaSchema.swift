//
//  MoaSchemaV1.swift
//  Data
//
//  Created by sanghyeon on 5/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData

public enum MoaSchemaV0: VersionedSchema {
    public static let versionIdentifier = Schema.Version(0, 0, 3)
    public static let models: [any PersistentModel.Type] = [
        PhotoEntity.self,
        AlbumEntity.self,
        PhotoLabelEntity.self,
        AlbumKeywordEntity.self,
        FaceEmbeddingEntity.self,
        HomeZoneEntity.self,
        ClusterEntity.self,
        ClusterBlacklistEntity.self
    ]
}
