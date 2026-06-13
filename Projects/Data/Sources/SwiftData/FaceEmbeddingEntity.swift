//
//  FaceEmbeddingEntity.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class FaceEmbeddingEntity {
    @Attribute(.unique) public var id: UUID
    public var embeddingData: Data
    public var boundingBoxX: Double
    public var boundingBoxY: Double
    public var boundingBoxWidth: Double
    public var boundingBoxHeight: Double
    public var hasGlasses: Bool = false

    public var photo: PhotoEntity?

    @Relationship(deleteRule: .nullify)
    public var cluster: ClusterEntity?

    public init(
        id: UUID = UUID(),
        embeddingData: Data,
        boundingBoxX: Double,
        boundingBoxY: Double,
        boundingBoxWidth: Double,
        boundingBoxHeight: Double,
        hasGlasses: Bool,
        photo: PhotoEntity? = nil,
        cluster: ClusterEntity? = nil
    ) {
        self.id = id
        self.embeddingData = embeddingData
        self.boundingBoxX = boundingBoxX
        self.boundingBoxY = boundingBoxY
        self.boundingBoxWidth = boundingBoxWidth
        self.boundingBoxHeight = boundingBoxHeight
        self.hasGlasses = hasGlasses
        self.photo = photo
        self.cluster = cluster
    }
}
