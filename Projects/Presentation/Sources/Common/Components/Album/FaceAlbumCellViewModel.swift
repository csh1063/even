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
        // album.displayName은 클러스터링 시점에 저장되는 데이터 값이라 항상 원문 "나"다(로케일 영향
        // 안 받음) — 여기서 String(localized:)로 비교하면 영어 로케일에서 "Me"로 바뀌어서 절대 안
        // 맞아떨어진다(AlbumDetailUseCase.swift가 원문 리터럴로 비교하는 것과 동일하게 맞춤).
        self.isHighlighted = album.displayName == "나"
    }

    var faceCellViewModel: FaceCellViewModel {
        FaceCellViewModel(albumId: album.id, photoId: localIdentifier, imageUseCase: imageUseCase, albumUseCase: albumUseCase)
    }
}
