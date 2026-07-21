//
//  FaceClusterService.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import Foundation
import UIKit

// MARK: - FaceClusterService

/// Chinese Whispers 기반 클러스터링 알고리즘 자체는 ClusteringEngine으로 옮겼고, 여기는 그걸
/// 사람 얼굴(AdaFace_IR50, 512차원) 기준값으로 감싸는 얇은 래퍼만 남았다.
public final class FaceClusterService {

    private let engine = ClusteringEngine<FaceEmbedding>(config: .faceDefault, logTag: "FaceClusterService")

    private let libraryService: PhotoLibraryService

    public init(libraryService: PhotoLibraryService) {
        self.libraryService = libraryService
    }

    private var debugSaveCount = 0

    private func save(id: String, boundingBox: CGRect) async throws {
        if let image = try await loadImage(photoId: id) {
            self.saveDebugCrop(image, boundingBox: boundingBox)
        }
    }

    private func saveDebugCrop(_ image: CGImage, boundingBox: CGRect) {
        guard debugSaveCount < 20 else { return }
        guard let cropped = cropFace(from: image, boundingBox: boundingBox) else { return }
        let uiImage = UIImage(cgImage: cropped)
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        debugSaveCount += 1
    }

    private func cropFace(from image: CGImage, boundingBox: CGRect) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        let scale: CGFloat = 1.1
        let expandedWidth = boundingBox.width * scale
        let expandedHeight = boundingBox.height * scale
        let expandedX = boundingBox.minX - (expandedWidth - boundingBox.width) / 2
        let expandedY = boundingBox.minY - (expandedHeight - boundingBox.height) / 2

        let clampedX = max(0, expandedX)
        let clampedY = max(0, expandedY)
        let clampedWidth = min(expandedWidth, 1.0 - clampedX)
        let clampedHeight = min(expandedHeight, 1.0 - clampedY)

        let rect = CGRect(
            x: clampedX * width,
            y: (1.0 - clampedY - clampedHeight) * height,
            width: clampedWidth * width,
            height: clampedHeight * height
        )
        return image.cropping(to: rect)
    }

    private func loadImage(photoId: String, size: CGFloat = 1024) async throws -> CGImage? {
        try await libraryService.loadImage(
            id: photoId,
            type: .specialSize(CGSize(width: size, height: size))
        )
    }

    // MARK: - Public

    public func cluster(embeddings: [FaceEmbedding]) -> [ClusterResult<FaceEmbedding>] {
        engine.cluster(embeddings: embeddings)
    }

    public func clusterWithLeftoverRetry(embeddings: [FaceEmbedding]) -> ClusteringOutcome<FaceEmbedding> {
        engine.clusterWithLeftoverRetry(embeddings: embeddings, maxRetryRounds: 3)
    }
}
