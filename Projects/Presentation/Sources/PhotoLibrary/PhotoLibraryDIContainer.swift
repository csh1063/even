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

//    let appDIContainer: AppDIContainer
//
//    init(appDIContainer: AppDIContainer) {
//        self.appDIContainer = appDIContainer
//    }
    
    private let photoLibraryRepository: PhotoLibraryRepository
    private let photoDataRepository: PhotoDataRepository
    
    public init(photoLibraryRepository: PhotoLibraryRepository,
                photoDataRepository: PhotoDataRepository) {
        self.photoLibraryRepository = photoLibraryRepository
        self.photoDataRepository = photoDataRepository
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

//    func makeHomeDetailViewModel(
//        id: String
//    ) -> HomeDetailViewModel {
//    }
}
