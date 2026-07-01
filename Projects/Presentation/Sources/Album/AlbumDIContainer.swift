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
        
        let albumUseCase = DefaultAlbumUseCase(
            albumRepository: appDIContainer.albumDataRepository
        )
        
        return AlbumViewModel(tabbarViewModel: tabbarViewModel,
                              imageUseCase: imageUseCase,
                              albumUseCase: albumUseCase)
    }

    func makeDetailDIContainer(album: Album, isSelectMode: Bool) -> AlbumDetailDIContainer {
        AlbumDetailDIContainer(
            album: album,
            photoLibraryRepository: appDIContainer.photoLibraryRepository,
            albumDataRepository: appDIContainer.albumDataRepository,
            labelRepository: appDIContainer.photoLabelDataRepository,
            isSelectMode: isSelectMode
        )
    }
    
    func makeListDIContainer(from: String) -> AlbumListDIContainer {
        AlbumListDIContainer(
            from: from,
            photoLibraryRepository: appDIContainer.photoLibraryRepository,
            albumDataRepository: appDIContainer.albumDataRepository,
            photoLabelDataRepository: appDIContainer.photoLabelDataRepository
        )
    }
}
