//
//  PhotoImageUseCase.swift
//  Domain
//
//  Created by sanghyeon on 4/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoImageUseCase {
    func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T>
}

public class DefaultPhotoImageUseCase: PhotoImageUseCase {
    
    private let repository: PhotoLibraryRepository
    
    public init(repository: PhotoLibraryRepository) {
        self.repository = repository
    }
    
    public func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T> {
        return try await self.repository.loadImage(id: id, type: type)
    }
}
