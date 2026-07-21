//
//  AnimalClusterEntity.swift
//  Data
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class AnimalClusterEntity {
    @Attribute(.unique) public var id: UUID
    public var centroidData: Data
    public var excludedPhotoIds: [String] = []
    public var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify)
    public var album: AlbumEntity?

    @Relationship(deleteRule: .nullify)
    public var animalEmbeddings: [AnimalEmbeddingEntity] = []

    public init(id: UUID = UUID(), centroidData: Data) {
        self.id = id
        self.centroidData = centroidData
    }
}
