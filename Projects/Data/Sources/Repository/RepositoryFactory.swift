//
//  RepositoryFactory.swift
//  Data
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import SwiftData

public final class RepositoryFactory {

    private let container: ModelContainer
    private let serviceFactory: ServiceFactory

    public init(container: ModelContainer, serviceFactory: ServiceFactory) {
        self.container = container
        self.serviceFactory = serviceFactory
    }
    
//    public var makeSplashRepository
//    public var makeMainRepository
    
    public lazy var photoLibraryRepository: PhotoLibraryRepository = {
        DefaultPhotoLibraryRepository(
            libraryService: serviceFactory.photoLibraryService,
            permissionService: serviceFactory.permissionService
        )
    }()
    
    public lazy var photoAnalysisRepository: PhotoAnalysisRepository = {
        DefaultPhotoAnalysisRepository(
            analysisService: serviceFactory.photoAnalysisService,
            libraryService: serviceFactory.photoLibraryService,
            geocoderService: serviceFactory.geocoderService
        )
    }()
    
    public lazy var photoDataRepository: PhotoDataRepository = {
        DefaultPhotoDataRepository(container: container)
    }()
    
    public lazy var folderDataRepository: FolderDataRepository = {
        DefaultFolderDataRepository(container: container)
    }()
    
    public lazy var photoLabelDataRepository: PhotoLabelDataRepository = {
        DefaultPhotoLabelDataRepository(container: container)
    }()
    
    public lazy var photoCategoryRepository: PhotoCategoryRepository = {
        DefaultPhotoCategoryRepository(service: serviceFactory.photoCategoryService)
    }()
}
