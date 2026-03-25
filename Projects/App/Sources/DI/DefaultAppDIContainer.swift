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
    
    let container: ModelContainer

    private lazy var photoLibraryRepository = repositoryFactory.makePhotoLibraryRepository()
    private lazy var photoAnalysisRepository = repositoryFactory.makePhotoAnalysisRepository()
    private lazy var photoDataRepository = repositoryFactory.makePhotoDataRepository()
    private lazy var folderDataRepository = repositoryFactory.makeFolderDataRepository()
    
    private lazy var serviceFactory = ServiceFactory()
    private lazy var repositoryFactory = RepositoryFactory(
        container: container,
        serviceFactory: serviceFactory
    )
    
    init() {
       do {
           container = try ModelContainer(
               for: PhotoEntity.self,
               FolderEntity.self,
               PhotoLabelEntity.self,
               FolderKeywordEntity.self
           )
       } catch {
           fatalError("ModelContainer 생성 실패: \(error)")
       }
    }
    
    // MARK: Splash
    func makeSplashUseCase() {
        
    }
    
    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel()
    }
    
    // MARK: Main
    func makeMainUseCase() {
        
    }
    
    func makeMainViewModel() -> MainViewModel {
        MainViewModel()
    }
    
    // MARK: Photo Library
    func makePhotoLibraryDIContainer() -> PhotoLibraryDIContainer {
        PhotoLibraryDIContainer(
            photoLibraryRepository: photoLibraryRepository
        )
    }
    
    // MARK: Album
    func makeAlbumDIContainer() -> AlbumDIContainer {
        AlbumDIContainer(photoLibraryRepository: photoLibraryRepository,
                         photoAnalysisRepository: photoAnalysisRepository,
                         photoDataRepository: photoDataRepository,
                         folderDataRepository: folderDataRepository)
    }
}
