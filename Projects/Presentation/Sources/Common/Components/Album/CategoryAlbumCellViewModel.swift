//
//  CategoryAlbumCellViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

struct CategoryAlbumCellViewModel: AlbumCellViewModel {
    
    var id: UUID
    var localIdentifier: String
    var displayName: String
    var formattedDate: String
    var photoCount: Int
    
    var album: Album
    var imageLoader: any ImageLoadable
    
    let systemIconName: String
    let iconColor: UIColor
    
    init(album: Album, imageLoader: any ImageLoadable) {
        self.id = album.id
        self.localIdentifier = album.coverPhotoIdentifier ?? ""
        self.displayName = album.displayName.replacingOccurrences(of: "_", with: " ")
        self.formattedDate = ""
        self.photoCount = album.photoCount
        self.album = album
        self.imageLoader = imageLoader

        // album.name == 카테고리 key
        switch album.name {
        case "food":
            systemIconName = "fork.knife"
            iconColor = Theme.primary
        case "nature":
            systemIconName = "leaf.fill"
            iconColor = Theme.positive
        case "city":
            systemIconName = "building.2.fill"
            iconColor = Theme.secondary
        case "event":
            systemIconName = "star.fill"
            iconColor = Theme.accent
        case "animal":
            systemIconName = "pawprint.fill"
            iconColor = UIColor("#A0784E")
        case "text_document":
            systemIconName = "doc.text.fill"
            iconColor = Theme.textSecondary
        case "sports":
            systemIconName = "figure.run"
            iconColor = Theme.warning
        case "vehicle":       
            systemIconName = "car.fill"
            iconColor = UIColor("#6B7AFF")
        default:
            systemIconName = "photo.fill"
            iconColor = Theme.textTertiary
        }
    }
}
