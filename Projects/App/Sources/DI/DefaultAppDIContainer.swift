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

    var photoLibraryRepository: PhotoLibraryRepository{
        repositoryFactory.photoLibraryRepository
    }
    
    var photoAnalysisRepository: PhotoAnalysisRepository{
        repositoryFactory.photoAnalysisRepository
    }
    
    var photoDataRepository: PhotoDataRepository{
        repositoryFactory.photoDataRepository
    }
    
    var folderDataRepository: FolderDataRepository{
        repositoryFactory.folderDataRepository
    }
    
    var photoLabelDataRepository: PhotoLabelDataRepository {
        repositoryFactory.photoLabelDataRepository
    }
    
    var photoCategoryRepository: PhotoCategoryRepository{
        repositoryFactory.photoCategoryRepository
    }
    
    var geoRepository: GeoRepository {
        repositoryFactory.geoRepository
    }
    
    private let providerFactory: ProviderFactory
    private lazy var executor: DefaultNetworkExecutor = {
        DefaultNetworkExecutor(providerFactory: providerFactory)
    }()
    
    private lazy var serviceFactory = ServiceFactory(executor: executor)
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
        self.providerFactory = ProviderFactory()
    }
    
    // MARK: Splash
    func makePhotoCheckUseCase() -> PhotoCheckUseCase {
        DefaultPhotoCheckUseCase(photoLibraryRepository: photoLibraryRepository,
                                 photoDataRepository: photoDataRepository,
                                 folderDataRepository: folderDataRepository
        )
    }
    
    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel(useCase: makePhotoCheckUseCase())
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
        AlbumDIContainer(appDIContainer: self)
//        AlbumDIContainer(photoLibraryRepository: photoLibraryRepository,
//                         photoAnalysisRepository: photoAnalysisRepository,
//                         photoDataRepository: photoDataRepository,
//                         folderDataRepository: folderDataRepository)
    }
    
    func makeMyPageDIContainer() -> MyPageDIContainer {
        MyPageDIContainer(appDIContainer: self)
    }
}
