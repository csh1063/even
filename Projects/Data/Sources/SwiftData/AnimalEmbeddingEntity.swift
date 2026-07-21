//
//  AnimalEmbeddingEntity.swift
//  Data
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class AnimalEmbeddingEntity {
    @Attribute(.unique) public var id: UUID
    public var embeddingData: Data
    public var boundingBoxX: Double
    public var boundingBoxY: Double
    public var boundingBoxWidth: Double
    public var boundingBoxHeight: Double
    public var species: String
    /// VNRecognizeAnimalsRequest 탐지 confidence (0~1) — 사람 얼굴의 captureQuality에 대응하는 대체 신호
    public var detectionConfidence: Double = 0

    public var photo: PhotoEntity?

    @Relationship(deleteRule: .nullify)
    public var cluster: AnimalClusterEntity?

    public init(
        id: UUID = UUID(),
        embeddingData: Data,
        boundingBoxX: Double,
        boundingBoxY: Double,
        boundingBoxWidth: Double,
        boundingBoxHeight: Double,
        species: String,
        detectionConfidence: Double = 0,
        photo: PhotoEntity? = nil,
        cluster: AnimalClusterEntity? = nil
    ) {
        self.id = id
        self.embeddingData = embeddingData
        self.boundingBoxX = boundingBoxX
        self.boundingBoxY = boundingBoxY
        self.boundingBoxWidth = boundingBoxWidth
        self.boundingBoxHeight = boundingBoxHeight
        self.species = species
        self.detectionConfidence = detectionConfidence
        self.photo = photo
        self.cluster = cluster
    }
}
