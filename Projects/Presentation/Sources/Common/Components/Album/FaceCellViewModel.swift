//
//  FaceCellViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

struct FaceCellViewModel: AlbumCellViewModel {
    
    var id: UUID
    var localIdentifier: String
    var displayName: String
    var formattedDate: String
    var photoCount: Int
    
    var folder: Folder
    var imageLoader: any ImageLoadable
    
    let isNamed: Bool             // 사용자가 이름 지정했는지
    let isHighlighted: Bool       // "나"로 지정된 경우
    
    init(folder: Folder, imageLoader: any ImageLoadable) {
        self.id = folder.id
        self.localIdentifier = folder.coverPhotoIdentifier ?? ""
        self.displayName = folder.displayName.replacingOccurrences(of: "_", with: " ")
        self.formattedDate = ""
        self.photoCount = folder.photoCount
        self.folder = folder
        self.imageLoader = imageLoader

        let hasCustomName  = folder.displayName != folder.name && !folder.displayName.isEmpty
        self.isNamed       = hasCustomName
        self.isHighlighted = folder.displayName == "나"
    }
}
