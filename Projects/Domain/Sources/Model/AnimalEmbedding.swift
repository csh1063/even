//
//  AnimalEmbedding.swift
//  Domain
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import CoreGraphics

/// VNRecognizeAnimalsRequest가 구분하는 종 — Vision 프레임워크가 실제로 주는 라벨은 이 둘뿐이다.
public enum AnimalSpecies: String, Hashable, Codable {
    case dog
    case cat
}

public struct AnimalEmbedding: Hashable, ClusterableEmbedding {
    public let id: UUID
    public let embedding: [Float]
    public let boundingBox: CGRect
    public let species: AnimalSpecies
    public let photoId: String
    /// VNRecognizeAnimalsRequest의 탐지 confidence. 사람 얼굴의 VNDetectFaceCaptureQualityRequest처럼
    /// "사진이 선명한가"를 재는 전용 지표가 동물 쪽엔 없어서, 커버 사진 선정 등에 쓰는 대체 신호로만 사용한다.
    public let detectionConfidence: Float

    public init(
        id: UUID = UUID(),
        embedding: [Float],
        boundingBox: CGRect,
        species: AnimalSpecies,
        photoId: String = "",
        detectionConfidence: Float = 0
    ) {
        self.id = id
        self.embedding = embedding
        self.boundingBox = boundingBox
        self.species = species
        self.photoId = photoId
        self.detectionConfidence = detectionConfidence
    }

    public static func == (lhs: AnimalEmbedding, rhs: AnimalEmbedding) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
