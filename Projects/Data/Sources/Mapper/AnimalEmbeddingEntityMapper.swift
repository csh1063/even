//
//  AnimalEmbeddingEntityMapper.swift
//  Data
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
import Domain
import CoreGraphics
import Foundation

extension AnimalEmbeddingEntity {
    public func toDomain() -> AnimalEmbedding {
        let embedding = embeddingData.withUnsafeBytes {
            Array($0.bindMemory(to: Float.self))
        }
        return AnimalEmbedding(
            id: id,
            embedding: embedding,
            boundingBox: CGRect(
                x: boundingBoxX,
                y: boundingBoxY,
                width: boundingBoxWidth,
                height: boundingBoxHeight
            ),
            species: AnimalSpecies(rawValue: species) ?? .dog,
            photoId: photo?.localIdentifier ?? "",
            detectionConfidence: Float(detectionConfidence)
        )
    }

    public static func from(domain: AnimalEmbedding, photo: PhotoEntity? = nil) -> AnimalEmbeddingEntity {
        let data = domain.embedding.withUnsafeBytes { Data($0) }
        return AnimalEmbeddingEntity(
            id: domain.id,
            embeddingData: data,
            boundingBoxX: domain.boundingBox.origin.x,
            boundingBoxY: domain.boundingBox.origin.y,
            boundingBoxWidth: domain.boundingBox.width,
            boundingBoxHeight: domain.boundingBox.height,
            species: domain.species.rawValue,
            detectionConfidence: Double(domain.detectionConfidence),
            photo: photo
        )
    }
}
