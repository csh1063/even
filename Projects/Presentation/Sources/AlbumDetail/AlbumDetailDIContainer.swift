//
//  AlbumDetailDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 3/28/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class AlbumDetailDIContainer {

    private let photoLibraryRepository: PhotoLibraryRepository
    private let albumDataRepository: AlbumDataRepository
    private let labelRepository: PhotoLabelDataRepository
    
    private let album: Album

    public init(album: Album,
                photoLibraryRepository: PhotoLibraryRepository,
                albumDataRepository: AlbumDataRepository,
                labelRepository: PhotoLabelDataRepository) {
        self.album = album
        self.photoLibraryRepository = photoLibraryRepository
        self.albumDataRepository = albumDataRepository
        self.labelRepository = labelRepository
    }

    func makeAlbumDetailViewModel() -> AlbumDetailViewModel {
        
        let imageUseCase = DefaultPhotoImageUseCase(
            repository: photoLibraryRepository
        )
        
        let albumDetailUseCase = DefaultAlbumDetailUseCase(
            repository: albumDataRepository
        )
        
        return AlbumDetailViewModel(album: album,
                                    imageUseCase: imageUseCase,
                                    detailUseCase: albumDetailUseCase)
    }
    
    func makeImageViewerViewModel(photoDetails: [PhotoDetail], index: Int) -> ImageViewerViewModel {
        
        let imageUseCase = DefaultImageViewerUseCase(
            repository: photoLibraryRepository,
            labelRepository: labelRepository
        )
        
        return ImageViewerViewModel(photoDetails: photoDetails,
                                    initialIndex: index,
                                    imageUseCase: imageUseCase)
    }
}
