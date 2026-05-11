//
//  AlbumDetailDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 3/28/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class AlbumDetailDIContainer {

    private let photoLibraryRepository: PhotoLibraryRepository
    private let folderDataRepository: FolderDataRepository
    private let labelRepository: PhotoLabelDataRepository
    
    private let folder: Folder

    public init(folder: Folder,
                photoLibraryRepository: PhotoLibraryRepository,
                folderDataRepository: FolderDataRepository,
                labelRepository: PhotoLabelDataRepository) {
        self.folder = folder
        self.photoLibraryRepository = photoLibraryRepository
        self.folderDataRepository = folderDataRepository
        self.labelRepository = labelRepository
    }

    func makeAlbumDetailViewModel() -> AlbumDetailViewModel {
        
        let imageUseCase = DefaultPhotoImageUseCase(
            repository: photoLibraryRepository
        )
        
        let folderDetailUseCase = DefaultFolderDetailUseCase(
            repository: folderDataRepository
        )
        
        return AlbumDetailViewModel(folder: folder,
                                    imageUseCase: imageUseCase,
                                    detailUseCase: folderDetailUseCase)
    }
    
    func makeImageViewerViewModel(photoDetails: [PhotoDetail], index: Int) -> ImageViewerViewModel {
        
        let imageUseCase = DefaultImageViewerUseCase(
            repository: photoLibraryRepository,
            labelRepository: labelRepository
        )
        
        return ImageViewerViewModel(photoDetails: photoDetails,
                                    initialIndex: index,
                                    imageUseCase: imageUseCase)
    }
}
