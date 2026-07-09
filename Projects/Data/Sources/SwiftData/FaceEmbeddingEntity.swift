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
    /// VNDetectFaceCaptureQualityRequest 점수 (0~1) — 앨범 대표 사진 선정에 boundingBox 크기 대신 사용
    public var captureQuality: Double = 0

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
        captureQuality: Double = 0,
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
        self.captureQuality = captureQuality
        self.photo = photo
        self.cluster = cluster
    }
}
