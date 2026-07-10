//
//  AlbumListDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 6/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class AlbumListDIContainer {

    private let photoLibraryRepository: PhotoLibraryRepository
    private let albumDataRepository: AlbumDataRepository
    private let photoLabelDataRepository: PhotoLabelDataRepository
    private let faceClusterRepository: FaceClusterRepository

    private let from: String

    public init(from: String,
                photoLibraryRepository: PhotoLibraryRepository,
                albumDataRepository: AlbumDataRepository,
                photoLabelDataRepository: PhotoLabelDataRepository,
                faceClusterRepository: FaceClusterRepository) {
        self.from = from
        self.photoLibraryRepository = photoLibraryRepository
        self.albumDataRepository = albumDataRepository
        self.photoLabelDataRepository = photoLabelDataRepository
        self.faceClusterRepository = faceClusterRepository
    }

    func makeAlbumListViewModel() -> AlbumListViewModel {

        let imageUseCase = DefaultPhotoImageUseCase(
            repository: photoLibraryRepository
        )

        let albumUseCase = DefaultAlbumUseCase(
            albumRepository: albumDataRepository
        )

        return AlbumListViewModel(from: from,
                                  imageUseCase: imageUseCase,
                                  albumUseCase: albumUseCase)
    }

    func makeDetailDIContainer(album: Album, isSelectMode: Bool) -> AlbumDetailDIContainer {
        AlbumDetailDIContainer(
            album: album,
            photoLibraryRepository: photoLibraryRepository,
            albumDataRepository: albumDataRepository,
            labelRepository: photoLabelDataRepository,
            faceClusterRepository: faceClusterRepository,
            isSelectMode: isSelectMode
        )
    }
}
