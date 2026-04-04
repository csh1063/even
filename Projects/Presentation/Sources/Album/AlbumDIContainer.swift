//
//  AlbumDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 1/5/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class AlbumDIContainer {

    let appDIContainer: AppDIContainer
    
    public init(appDIContainer: AppDIContainer) {
        self.appDIContainer = appDIContainer
    }
    
    func makeAlbumViewModel(coordinator: AlbumCoordinator) -> AlbumViewModel {
        
        let photoUseCase = DefaultPhotoLibraryUseCase(
            repository: appDIContainer.photoLibraryRepository
        )
        
        // MARK: Album
        let analysisUseCase = DefaultPhotoAnalysisUseCase(
            libraryRepository: appDIContainer.photoLibraryRepository,
            analysisRepository: appDIContainer.photoAnalysisRepository,
            dataRepository: appDIContainer.photoDataRepository
        )
        
        let autoFolderUseCase = DefaultAutoFolderUseCase(
            photoDataRepository: appDIContainer.photoDataRepository,
            folderDataRepository: appDIContainer.folderDataRepository,
            photoCategoryRepository: appDIContainer.photoCategoryRepository)
        
        let folderUseCase = DefaultFolderUseCase(
            folderRepository: appDIContainer.folderDataRepository
        )
        
        return AlbumViewModel(coordinator: coordinator,
                              photoUseCase: photoUseCase,
                              analysisUseCase: analysisUseCase,
                              autoFolderUseCase: autoFolderUseCase,
                              folderUseCase: folderUseCase)
    }

    func makeDetailDIContainer(folder: Folder) -> AlbumDetailDIContainer {
        AlbumDetailDIContainer(
            folder: folder,
            photoLibraryRepository: appDIContainer.photoLibraryRepository,
            folderDataRepository: appDIContainer.folderDataRepository
        )
    }
}
