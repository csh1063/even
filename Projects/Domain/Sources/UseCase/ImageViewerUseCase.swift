//
//  ImageViewerUseCase.swift
//  Domain
//
//  Created by sanghyeon on 5/10/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public protocol ImageViewerUseCase {
    func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T>
    func getLabels(by localIdentifier: String) async throws -> [PhotoLabel]
}

public class DefaultImageViewerUseCase: ImageViewerUseCase {

    private let repository: PhotoLibraryRepository
    private let labelRepository: PhotoLabelDataRepository

    public init(repository: PhotoLibraryRepository,
                labelRepository: PhotoLabelDataRepository) {
        self.repository = repository
        self.labelRepository = labelRepository
    }

    public func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T> {
        return try await self.repository.loadImage(id: id, type: type)
    }

    public func getLabels(by localIdentifier: String) async throws -> [PhotoLabel] {
        return try self.labelRepository.fetchLabelsByPhoto(localIdentifier: localIdentifier)
    }
}
