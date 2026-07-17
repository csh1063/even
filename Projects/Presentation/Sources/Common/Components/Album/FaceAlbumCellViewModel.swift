//
//  FaceAlbumCellViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

struct FaceAlbumCellViewModel: AlbumCellViewModel {

    var id: UUID
    var localIdentifier: String
    var displayName: String
    var formattedDate: String
    var photoCount: Int

    var album: Album
    var imageLoader: any ImageLoadable
    let imageUseCase: PhotoImageUseCase
    let albumUseCase: AlbumUseCase

    let isNamed: Bool             // 사용자가 이름 지정했는지
    let isHighlighted: Bool       // "나"로 지정된 경우

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

        self.isNamed       = album.isRenamed
        self.isHighlighted = album.displayName == "나"
    }

    var faceCellViewModel: FaceCellViewModel {
        FaceCellViewModel(albumId: album.id, photoId: localIdentifier, imageUseCase: imageUseCase, albumUseCase: albumUseCase)
    }
}
