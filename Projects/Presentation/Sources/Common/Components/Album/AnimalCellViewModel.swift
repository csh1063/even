//
//  AnimalCellViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

/// 동물 앨범 커버를 전체 사진이 아니라 동물만 크롭해서 보여주기 위한 뷰모델 — FaceCellViewModel과 동일한 패턴
struct AnimalCellViewModel {
    let albumId: UUID
    let photoId: String
    let imageUseCase: PhotoImageUseCase
    let albumUseCase: AlbumUseCase

    private let sourceLoadSize = CGSize(width: 1024, height: 1024)

    func loadAnimalImage() async -> UIImage? {
        guard !photoId.isEmpty else { return nil }
        do {
            guard let cgImage: CGImage = try await imageUseCase.loadImage(
                id: photoId,
                type: .specialSize(sourceLoadSize)
            ).cgImage else {
                return nil
            }

            guard let boundingBox = try await albumUseCase.fetchCoverAnimalBoundingBox(albumId: albumId),
                  let cropped = crop(cgImage, to: boundingBox) else {
                return UIImage(cgImage: cgImage)
            }
            return UIImage(cgImage: cropped)
        } catch {
            return nil
        }
    }

    /// boundingBox는 Vision 정규화 좌표(원점 좌하단, 0~1) 기준
    private func crop(_ image: CGImage, to boundingBox: CGRect) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        let scale: CGFloat = 1
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
}
