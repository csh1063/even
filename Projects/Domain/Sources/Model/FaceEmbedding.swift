//
//  FaceEmbedding.swift
//  Domain
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import CoreGraphics

public struct FaceEmbedding: Hashable {
    public let id: UUID
    public let embedding: [Float]
    public let boundingBox: CGRect
    public let hasGlasses: Bool
    public let photoId: String

    public init(
        id: UUID = UUID(),
        embedding: [Float],
        boundingBox: CGRect,
        hasGlasses: Bool,
        photoId: String = ""
    ) {
        self.id = id
        self.embedding = embedding
        self.boundingBox = boundingBox
        self.hasGlasses = hasGlasses
        self.photoId = photoId
    }

    public static func == (lhs: FaceEmbedding, rhs: FaceEmbedding) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
