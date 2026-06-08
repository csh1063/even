//
//  FaceEmbeddingEntityMapper.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import CoreGraphics
import Foundation

// MARK: - Mapping
extension FaceEmbeddingEntity {
    public func toDomain() -> FaceEmbedding {
        let embedding = embeddingData.withUnsafeBytes {
            Array($0.bindMemory(to: Float.self))
        }
        return FaceEmbedding(
            id: id,
            embedding: embedding,
            boundingBox: CGRect(
                x: boundingBoxX,
                y: boundingBoxY,
                width: boundingBoxWidth,
                height: boundingBoxHeight
            ),
            hasGlasses: hasGlasses,
            clusterId: clusterId,
            photoId: photo?.localIdentifier ?? "nil"
        )
    }

    public static func from(domain: FaceEmbedding, photo: PhotoEntity? = nil) -> FaceEmbeddingEntity {
        let data = domain.embedding.withUnsafeBytes { Data($0) }
        return FaceEmbeddingEntity(
            id: domain.id,
            embeddingData: data,
            boundingBoxX: domain.boundingBox.origin.x,
            boundingBoxY: domain.boundingBox.origin.y,
            boundingBoxWidth: domain.boundingBox.width,
            boundingBoxHeight: domain.boundingBox.height,
            hasGlasses: domain.hasGlasses,
            clusterId: domain.clusterId,
            photo: photo
        )
    }
}
