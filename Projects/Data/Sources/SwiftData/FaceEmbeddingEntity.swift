//
//  FaceEmbeddingEntity.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation
import Domain

@Model
public final class FaceEmbeddingEntity {
    @Attribute(.unique) public var id: UUID
    public var embeddingData: Data       // [Float] → Data 직렬화
    public var boundingBoxX: Double
    public var boundingBoxY: Double
    public var boundingBoxWidth: Double
    public var boundingBoxHeight: Double
    public var hasGlasses: Bool = false
    public var clusterId: String?

    public var photo: PhotoEntity?

    public init(
        id: UUID = UUID(),
        embeddingData: Data,
        boundingBoxX: Double,
        boundingBoxY: Double,
        boundingBoxWidth: Double,
        boundingBoxHeight: Double,
        hasGlasses: Bool,
        clusterId: String? = nil,
        photo: PhotoEntity? = nil
    ) {
        self.id = id
        self.embeddingData = embeddingData
        self.boundingBoxX = boundingBoxX
        self.boundingBoxY = boundingBoxY
        self.boundingBoxWidth = boundingBoxWidth
        self.boundingBoxHeight = boundingBoxHeight
        self.hasGlasses = hasGlasses
        self.clusterId = clusterId
        self.photo = photo
    }
}
