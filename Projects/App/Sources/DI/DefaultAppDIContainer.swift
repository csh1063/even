//
//  DefaultAppDIContainer.swift
//  App
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Presentation
import Data
import Domain

@MainActor
final class DefaultAppDIContainer: AppDIContainer {
    
    init() {
        
    }
    
    // MARK: Splash
    func makeSplashRepository() {
        
    }
    
    func makeSplashUseCase() {
        
    }
    
    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel()
    }
    
    // MARK: Main
    func makeMainRepository() {
        
    }
    
    func makeMainUseCase() {
        
    }
    
    func makeMainViewModel() -> MainViewModel {
        MainViewModel()
    }
    
    // MARK: Photo Library
    func makePhotoLibraryRepository() -> PhotoLibraryRepository {
        let libraryService = PhotoLibraryService()
        let permissionService = PermissionService()
        return DefaultPhotoLibraryRepository(
            libraryService: libraryService,
            permissionService: permissionService
        )
    }
    
    func makePhotoLibraryUseCase() -> PhotoLibraryUseCase {
        return DefaultPhotoLibraryUseCase(repository: makePhotoLibraryRepository())
    }
    
    func makePhotoLibraryViewModel() -> PhotoLibraryViewModel {
        return PhotoLibraryViewModel(useCase: makePhotoLibraryUseCase())
    }
    
    // MARK: Album
    func makePhotoAnalysisRepository() -> PhotoAnalysisRepository {
        let analysisService = PhotoAnalysisService()
        let libraryService = PhotoLibraryService()
        let geocoderService = GeocoderService()
        return DefaultPhotoAnalysisRepository(
            analysisService: analysisService,
            libraryService: libraryService,
            geocoderService: geocoderService
        )
    }
    
    func makePhotoAnalysisUseCase() -> PhotoAnalysisUseCase {
        return PhotoAnalysisUseCase(
            libraryRepository: makePhotoLibraryRepository(),
            analysisRepository: makePhotoAnalysisRepository()
        )
    }
    
    func makePhotoLocationAnalysisUseCase() -> PhotoLocationAnalysisUseCase {
        return PhotoLocationAnalysisUseCase(
            libraryRepository: makePhotoLibraryRepository(),
            analysisRepository: makePhotoAnalysisRepository()
        )
    }
    
    func makeAlbumViewModel() -> AlbumViewModel {
        return AlbumViewModel(
            analysisUseCase: makePhotoAnalysisUseCase(),
            locationAnalysisUseCase: makePhotoLocationAnalysisUseCase()
        )
    }
}
