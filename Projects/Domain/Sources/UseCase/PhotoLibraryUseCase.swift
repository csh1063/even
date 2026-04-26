//
//  PhotoLibraryUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoLibraryUseCase {
    func fetchData(page: Int) async throws -> PhotoList
    func checkPermission() async throws -> PhotoPermission
//    func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T>
}

public class DefaultPhotoLibraryUseCase: PhotoLibraryUseCase {
    
    private let repository: PhotoLibraryRepository
    private let dataRepository: PhotoDataRepository
    
    public init(repository: PhotoLibraryRepository, dataRepository: PhotoDataRepository) {
        self.repository = repository
        self.dataRepository = dataRepository
    }
    
    public func fetchData(page: Int) async throws -> PhotoList {
        
        let photoList = try await self.repository.fetchPhotos(page: page)
        let analyzedIds = Set(try dataRepository.fetchAnalyzed())
        let updatedPhotos = photoList.photos.map { photo -> PhotoInAlbum in
            var updatedPhoto = photo
            
            if !analyzedIds.contains(photo.localIdentifier) {
                updatedPhoto.isUnanalysis = true
            } else {
                updatedPhoto.isUnanalysis = false
            }
            
            return updatedPhoto
        }
        
        return PhotoList(
            title: photoList.title,
            photos: updatedPhotos,
            hasNext: photoList.hasNext
        )
        
    }
    
    public func checkPermission() async throws -> PhotoPermission {
        try await self.repository.checkPermission()
    }
    
//    public func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T> {
//        return try await self.repository.loadImage(id: id, type: type)
//    }
}
