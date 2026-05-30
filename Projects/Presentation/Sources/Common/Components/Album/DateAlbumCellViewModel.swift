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
    
    var folder: Folder
    
    var imageLoader: any ImageLoadable
    
    init(folder: Folder, imageLoader: any ImageLoadable) {
        self.id = folder.id
        self.localIdentifier = folder.coverPhotoIdentifier ?? ""
        self.displayName = folder.displayName.replacingOccurrences(of: "_", with: " ")
        self.formattedDate = ""
        self.photoCount = folder.photoCount
        self.folder = folder
        self.imageLoader = imageLoader
    }
}
