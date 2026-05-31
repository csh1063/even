//
//  TimeYearItemViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

struct DateAlbumCellViewModel: AlbumCellViewModel {
    
    var id: UUID
    var localIdentifier: String
    var displayName: String
    var formattedDate: String
    
    var photoCount: Int
    
    var album: Album
    
    var imageLoader: any ImageLoadable
    
    init(album: Album, imageLoader: any ImageLoadable) {
        self.id = album.id
        self.localIdentifier = album.coverPhotoIdentifier ?? ""
        self.displayName = album.displayName.replacingOccurrences(of: "_", with: " ")
        self.formattedDate = ""
        self.photoCount = album.photoCount
        self.album = album
        self.imageLoader = imageLoader
    }
}
