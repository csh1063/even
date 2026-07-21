//
//  AnimalAlbumCellViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

/// FaceAlbumCellViewModel과 동일한 패턴 — "나" 자동 하이라이트 개념만 없다 (동물에는 해당 없음)
struct AnimalAlbumCellViewModel: AlbumCellViewModel {

    var id: UUID
    var localIdentifier: String
    var displayName: String
    var formattedDate: String
    var photoCount: Int

    var album: Album
    var imageLoader: any ImageLoadable
    let imageUseCase: PhotoImageUseCase
    let albumUseCase: AlbumUseCase

    let isNamed: Bool

    init(album: Album, imageLoader: any ImageLoadable, imageUseCase: PhotoImageUseCase, albumUseCase: AlbumUseCase) {
        self.id = album.id
        self.localIdentifier = album.coverPhotoIdentifier ?? ""
        self.displayName = album.displayName.replacingOccurrences(of: "_", with: " ")
        self.formattedDate = ""
        self.photoCount = album.photoCount
        self.album = album
        self.imageLoader = imageLoader
        self.imageUseCase = imageUseCase
        self.albumUseCase = albumUseCase

        self.isNamed = album.isRenamed
    }

    var animalCellViewModel: AnimalCellViewModel {
        AnimalCellViewModel(albumId: album.id, photoId: localIdentifier, imageUseCase: imageUseCase, albumUseCase: albumUseCase)
    }
}
