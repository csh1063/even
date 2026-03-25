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
    
    let photoLibraryRepository: PhotoLibraryRepository
    
    public init(photoLibraryRepository: PhotoLibraryRepository) {
        self.photoLibraryRepository = photoLibraryRepository
    }

    func makePhotoLibraryViewModel() -> PhotoLibraryViewModel {
        let usecase = DefaultPhotoLibraryUseCase(
            repository: photoLibraryRepository
        )
        
        return PhotoLibraryViewModel(useCase: usecase)
    }

//    func makeHomeDetailViewModel(
//        id: String
//    ) -> HomeDetailViewModel {
//    }
}
