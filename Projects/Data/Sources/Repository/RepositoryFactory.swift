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
    
    public func makeSplashRepository() {
        
    }
    
    public func makeMainRepository() {
        
    }
    
    public func makePhotoLibraryRepository() -> PhotoLibraryRepository {
        DefaultPhotoLibraryRepository(
            libraryService: serviceFactory.makePhotoLibraryService(),
            permissionService: serviceFactory.makePermissionService()
        )
    }
    
    public func makePhotoAnalysisRepository() -> PhotoAnalysisRepository {
        DefaultPhotoAnalysisRepository(
            analysisService: serviceFactory.makePhotoAnalysisService(),
            libraryService: serviceFactory.makePhotoLibraryService(),
            geocoderService: serviceFactory.makeGeocoderService()
        )
    }
    
    public func makePhotoDataRepository() -> PhotoDataRepository {
        DefaultPhotoDataRepository(container: container)
    }
    
    public func makeFolderDataRepository() -> FolderDataRepository {
        DefaultFolderDataRepository(container: container)
    }
    
}
