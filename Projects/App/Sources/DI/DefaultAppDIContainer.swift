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
import SwiftData

@MainActor
final class DefaultAppDIContainer: AppDIContainer {
    
    var container: ModelContainer {
        do {
            let container = try ModelContainer(
                for: PhotoEntity.self,
                FolderEntity.self,
                PhotoLabelEntity.self,
                FolderKeywordEntity.self
            )
            
            return container
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }
    
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
        DefaultPhotoLibraryUseCase(repository: makePhotoLibraryRepository())
    }
    
    func makePhotoLibraryViewModel() -> PhotoLibraryViewModel {
        PhotoLibraryViewModel(useCase: makePhotoLibraryUseCase())
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
    
    func makePhotoDataRepository() -> PhotoDataRepository {
        DefaultPhotoDataRepository(container: container)
//        return DefaultPhotoDataRepository(context: context)
    }
    
    func makePhotoAnalysisUseCase() -> PhotoAnalysisUseCase {
        PhotoAnalysisUseCase(
            libraryRepository: makePhotoLibraryRepository(),
            analysisRepository: makePhotoAnalysisRepository(),
            dataRepository: makePhotoDataRepository()
        )
    }
    
    func makeFolderDataRepository() -> FolderDataRepository {
        DefaultFolderDataRepository(container: container)
    }
    
    func makeAutoFolderUseCase() -> AutoFolderUseCase {
        AutoFolderUseCase(
            photoDataRepository: makePhotoDataRepository(),
            folderDataRepository: makeFolderDataRepository())
    }
    
    func makeFolderUseCase() -> FolderUseCase {
        FolderUseCase(folderRepository: makeFolderDataRepository())
    }
    
    func makeAlbumViewModel() -> AlbumViewModel {
        AlbumViewModel(
            photoUseCase: makePhotoLibraryUseCase(),
            analysisUseCase: makePhotoAnalysisUseCase(),
            autoFolderUseCase: makeAutoFolderUseCase(),
            folderUseCase: makeFolderUseCase()
        )
    }
}
