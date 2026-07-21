//
//  FaceEmbedding.swift
//  Domain
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import CoreGraphics

public struct FaceEmbedding: Hashable, ClusterableEmbedding {
    public let id: UUID
    public let embedding: [Float]
    public let boundingBox: CGRect
    public let hasGlasses: Bool
    public let photoId: String
    /// Apple Vision의 VNDetectFaceCaptureQualityRequest 점수 (흐림/노출/각도 등을 종합한 화질 지표, 0~1).
    /// 앨범 대표 사진을 boundingBox 크기가 아니라 실제 화질로 고르기 위해 저장한다.
    public let captureQuality: Float

    public init(
        id: UUID = UUID(),
        embedding: [Float],
        boundingBox: CGRect,
        hasGlasses: Bool,
        photoId: String = "",
        captureQuality: Float = 0
    ) {
        self.id = id
        self.embedding = embedding
        self.boundingBox = boundingBox
        self.hasGlasses = hasGlasses
        self.photoId = photoId
        self.captureQuality = captureQuality
    }

    public static func == (lhs: FaceEmbedding, rhs: FaceEmbedding) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
