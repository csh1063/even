//
//  AlbumDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 1/5/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//`

import Foundation
import Domain

@MainActor
public final class AlbumDIContainer {

//    let appDIContainer: AppDIContainer
    //    init(appDIContainer: AppDIContainer) {
    //        self.appDIContainer = appDIContainer
    //    }
    let photoLibraryRepository: PhotoLibraryRepository
    let photoAnalysisRepository: PhotoAnalysisRepository
    let photoDataRepository: PhotoDataRepository
    let folderDataRepository: FolderDataRepository

    public init(photoLibraryRepository: PhotoLibraryRepository,
                photoAnalysisRepository: PhotoAnalysisRepository,
                photoDataRepository: PhotoDataRepository,
                folderDataRepository: FolderDataRepository) {
        self.photoLibraryRepository = photoLibraryRepository
        self.photoAnalysisRepository = photoAnalysisRepository
        self.photoDataRepository = photoDataRepository
        self.folderDataRepository = folderDataRepository
    }

    func makeAlbumViewModel() -> AlbumViewModel {
        
        let photoUseCase = DefaultPhotoLibraryUseCase(
            repository: photoLibraryRepository
        )
        
        // MARK: Album
        let analysisUseCase = PhotoAnalysisUseCase(
            libraryRepository: photoLibraryRepository,
            analysisRepository: photoAnalysisRepository,
            dataRepository: photoDataRepository
        )
        
        let autoFolderUseCase = AutoFolderUseCase(
            photoDataRepository: photoDataRepository,
            folderDataRepository: folderDataRepository)
        
        let folderUseCase = FolderUseCase(
            folderRepository: folderDataRepository
        )
        
        return AlbumViewModel(photoUseCase: photoUseCase,
                              analysisUseCase: analysisUseCase,
                              autoFolderUseCase: autoFolderUseCase,
                              folderUseCase: folderUseCase)
    }

//    func makeDetailDIContainer(
//        itemID: String
//    ) -> Tab1DetailDIContainer {
//        Tab1DetailDIContainer(
//            appDIContainer: appDIContainer,
//            itemID: itemID
//        )
//    }
}
