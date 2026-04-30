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
    
    func makeAlbumViewModel(tabbarViewModel: TabbarViewModel) -> AlbumViewModel {
        
        let imageUseCase = DefaultPhotoImageUseCase(
            repository: appDIContainer.photoLibraryRepository
        )
        
        let folderUseCase = DefaultFolderUseCase(
            folderRepository: appDIContainer.folderDataRepository
        )
        
        return AlbumViewModel(tabbarViewModel: tabbarViewModel,
                              imageUseCase: imageUseCase,
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
