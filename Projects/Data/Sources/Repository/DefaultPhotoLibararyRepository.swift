//
//  DefaultPhotoLibararyRepository.swift
//  Data
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

public final class DefaultPhotoLibararyRepository: PhotoLibararyRepository {

    private let service: PhotoLibararyService
    
    public init(service: PhotoLibararyService) {
        self.service = service
    }

    public func fetchPhotos(page: Int) async throws -> PhotoList {
        return try await self.service.getPhotoList(page: page).toDomain()
    }
    
    public func checkPermission() async throws -> PhotoPermission {
        try await self.service.checkPermission()
    }
    
    public func loadImage(id: String, type: LoadPhotoOptionType) async throws -> ImageData {
        let cgImage = try await self.service.loadImage(id: id, type: type)
        return ImageData(cgImage: cgImage)
    }
}

