//
//  FaceEmbedding.swift
//  Domain
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct FaceEmbedding: Hashable {
    public let id: UUID
    public let embedding: [Float]       // 512차원 벡터
    public let boundingBox: CGRect      // 원본 이미지 기준 얼굴 위치
    public let clusterId: String?       // 클러스터링 후 할당되는 사람 ID
    public let hasGlasses: Bool
    public let photoId: String

    public init(
        id: UUID = UUID(),
        embedding: [Float],
        boundingBox: CGRect,
        hasGlasses: Bool,
        clusterId: String? = nil,
        photoId: String = ""
    ) {
        self.id = id
        self.embedding = embedding
        self.boundingBox = boundingBox
        self.hasGlasses = hasGlasses
        self.clusterId = clusterId
        self.photoId = photoId
    }

    public static func == (lhs: FaceEmbedding, rhs: FaceEmbedding) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
