//
//  ClusterEntity.swift
//  Data
//
//  Created by sanghyeon on 6/9/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class ClusterEntity {
    @Attribute(.unique) public var id: UUID
    public var centroidData: Data
    public var excludedPhotoIds: [String] = []
    public var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify)
    public var album: AlbumEntity?

    @Relationship(deleteRule: .nullify)
    public var faceEmbeddings: [FaceEmbeddingEntity] = []

    public init(id: UUID = UUID(), centroidData: Data) {
        self.id = id
        self.centroidData = centroidData
    }
}
