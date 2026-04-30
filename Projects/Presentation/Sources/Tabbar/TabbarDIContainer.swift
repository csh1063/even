//
//  TabbarDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class TabbarDIContainer {
    
    private let appDiContainer: AppDIContainer
    
    public init(appDiContainer: AppDIContainer) {
        self.appDiContainer = appDiContainer
    }
    
    func makeTabbarViewModel() -> TabbarViewModel {
        
        let analysisUseCase = DefaultPhotoAnalysisUseCase(
            libraryRepository: appDiContainer.photoLibraryRepository,
            analysisRepository: appDiContainer.photoAnalysisRepository,
            dataRepository: appDiContainer.photoDataRepository,
            geoRepository: appDiContainer.geoRepository
        )
        
        let autoFolderUseCase = DefaultAutoFolderUseCase(
            photoDataRepository: appDiContainer.photoDataRepository,
            folderDataRepository: appDiContainer.folderDataRepository,
            photoCategoryRepository: appDiContainer.photoCategoryRepository
        )
        
        return TabbarViewModel(analysisUseCase: analysisUseCase,
                               autoFolderUseCase: autoFolderUseCase)
    }
    
    func makePhotoLibraryDIContainer() -> PhotoLibraryDIContainer {
        PhotoLibraryDIContainer(
            photoLibraryRepository: appDiContainer.photoLibraryRepository,
            photoDataRepository: appDiContainer.photoDataRepository
        )
    }
    
    func makeAlbumDIContainer() -> AlbumDIContainer {
        AlbumDIContainer(appDIContainer: appDiContainer)
    }
    
    func makeMyPageDIContainer() -> MyPageDIContainer {
        MyPageDIContainer(appDIContainer: appDiContainer)
    }
}
