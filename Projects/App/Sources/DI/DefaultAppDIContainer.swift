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
                FolderPhotoMapEntity.self,
                PhotoLabelEntity.self,
                FolderKeywordEntity.self
            )
            
            // DI 컨테이너에 context 주입
            return container
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }
//    var context: ModelContext {
//        do {
//            let container = try ModelContainer(
//                for: PhotoEntity.self,
//                FolderEntity.self,
//                FolderPhotoMapEntity.self,
//                PhotoLabelEntity.self,
//                FolderKeywordEntity.self
//            )
//            
//            // DI 컨테이너에 context 주입
//            return container.mainContext
//        } catch {
//            fatalError("ModelContainer 생성 실패: \(error)")
//        }
//    }
    
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
    
    func makePhotoDataRepository() -> PhotoDataRepository {
        return DefaultPhotoDataRepository(container: container)
//        return DefaultPhotoDataRepository(context: context)
    }
    
    func makePhotoAnalysisUseCase() -> PhotoAnalysisUseCase {
        return PhotoAnalysisUseCase(
            libraryRepository: makePhotoLibraryRepository(),
            analysisRepository: makePhotoAnalysisRepository(),
            dataRepository: makePhotoDataRepository()
        )
    }
    
    func makeAlbumViewModel() -> AlbumViewModel {
        return AlbumViewModel(useCase: makePhotoAnalysisUseCase())
    }
}
