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
    func fetchPhoto(page: Int) async throws -> PhotoList
    func checkPermission() async throws -> PhotoPermission
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
    
    public func fetchPhoto(page: Int) async throws -> PhotoList {
        
        let library = try await self.repository.fetchPhotos(page: page)
        
        let photos = try dataRepository.fetchPhotos()
        
        let photoMap = Dictionary(uniqueKeysWithValues: photos.map { ($0.localIdentifier, $0) })
        
        let updatedPhotos = library.photos.map { libraryPhoto -> PhotoInAlbum in
            var updatedPhoto = libraryPhoto
            if let photo = photoMap[libraryPhoto.localIdentifier] {
                updatedPhoto.photo = photo
            }
            return updatedPhoto
        }
        
        return PhotoList(
            title: library.title,
            photos: updatedPhotos,
            hasNext: library.hasNext
        )
    }
    
    public func checkPermission() async throws -> PhotoPermission {
        try await self.repository.checkPermission()
    }
}
