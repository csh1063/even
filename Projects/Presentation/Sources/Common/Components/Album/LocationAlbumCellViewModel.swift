//
//  LocationAlbumCellViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

struct LocationAlbumCellViewModel: AlbumCellViewModel {
    
    var id: UUID
    var localIdentifier: String
    var displayName: String
    var formattedDate: String
    var photoCount: Int
    
    var folder: Folder
    var imageLoader: any ImageLoadable
    
    let subText: String           // 구/군 ex) "마포구 · 성동구"
    let isMost: Bool
    let pinColor: UIColor

    init(folder: Folder, imageLoader: any ImageLoadable, isMost: Bool) {
        self.id = folder.id
        self.localIdentifier = folder.coverPhotoIdentifier ?? ""
        self.displayName = folder.displayName.replacingOccurrences(of: "_", with: " ")
        self.formattedDate = ""
        self.photoCount = folder.photoCount
        self.folder = folder
        self.imageLoader = imageLoader
        
        self.isMost               = isMost
        self.pinColor             = isMost ? Theme.primary : Theme.secondary

        self.subText = folder.keywords.joined(separator: ", ")
        
        print("folder.displayName:", folder.displayName, ", subText:", subText)
    }

    // isMost/pinColor 교체용 (AlbumViewModel 내부에서 사용)
    init(copying vm: LocationAlbumCellViewModel, isMost: Bool) {
        self.id = vm.id
        self.localIdentifier      = vm.localIdentifier
        self.displayName          = vm.displayName
        self.formattedDate = vm.formattedDate
        self.photoCount           = vm.photoCount
        self.folder = vm.folder
        self.imageLoader = vm.imageLoader
        
        self.subText              = vm.subText
        self.isMost               = isMost
        self.pinColor             = isMost ? Theme.primary : Theme.secondary
    }
}
