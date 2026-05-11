//
//  PhotoLibraryDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 1/5/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class PhotoLibraryDIContainer {
    
    private let photoLibraryRepository: PhotoLibraryRepository
    private let photoDataRepository: PhotoDataRepository
    private let labelDataRepository: PhotoLabelDataRepository
    
    public init(photoLibraryRepository: PhotoLibraryRepository,
                photoDataRepository: PhotoDataRepository,
                labelDataRepository: PhotoLabelDataRepository) {
        self.photoLibraryRepository = photoLibraryRepository
        self.photoDataRepository = photoDataRepository
        self.labelDataRepository = labelDataRepository
    }

    func makePhotoLibraryViewModel() -> PhotoLibraryViewModel {
        let useCase = DefaultPhotoLibraryUseCase(
            repository: photoLibraryRepository,
            dataRepository: photoDataRepository
        )
        let imageUseCase = DefaultPhotoImageUseCase(
            repository: photoLibraryRepository
        )
        
        return PhotoLibraryViewModel(useCase: useCase, imageUseCase: imageUseCase)
    }

    func makeImageViewerViewModel(photoDetails: [PhotoDetail], index: Int) -> ImageViewerViewModel {
        
        let imageUseCase = DefaultImageViewerUseCase(
            repository: photoLibraryRepository,
            labelRepository: labelDataRepository
        )
        
        return ImageViewerViewModel(photoDetails: photoDetails,
                                    initialIndex: index,
                                    imageUseCase: imageUseCase)
    }
}
