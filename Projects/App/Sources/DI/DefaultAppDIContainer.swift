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
    
    func makeSplashUsecase() {
        
    }
    
    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel()
    }
    
    // MARK: Main
    func makeMainRepository() {
        
    }
    
    func makeMainUsecase() {
        
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
    
    func makePhotoLibraryUsecase() -> PhotoLibraryUsecase {
        return DefaultPhotoLibraryUsecase(repository: makePhotoLibraryRepository())
    }
    
    func makePhotoLibraryViewModel() -> PhotoLibraryViewModel {
        return PhotoLibraryViewModel(usecase: makePhotoLibraryUsecase())
    }
    
    // MARK: Album
    func makePhotoAnalysisRepository() -> PhotoAnalysisRepository {
        let analysisService = PhotoAnalysisService()
        let libraryService = PhotoLibraryService()
        return DefaultPhotoAnalysisRepository(
            analysisService: analysisService,
            libraryService: libraryService
        )
    }
    
    func makePhotoAnalysisUsecase() -> PhotoAnalysisUsecase {
        return PhotoAnalysisUsecase(
            libraryRepository: makePhotoLibraryRepository(),
            analysisRepository: makePhotoAnalysisRepository()
        )
    }
    
    func makeAlbumViewModel() -> AlbumViewModel {
        return AlbumViewModel(analysisUsecase: makePhotoAnalysisUsecase())
    }
}
