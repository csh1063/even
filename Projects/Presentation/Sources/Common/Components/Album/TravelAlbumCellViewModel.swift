//
//  TravelAlbumCellViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

struct TravelAlbumCellViewModel: AlbumCellViewModel {
    
    var id: UUID
    var localIdentifier: String
    var displayName: String
    var formattedDate: String
    var photoCount: Int
    
    var album: Album
    var imageLoader: any ImageLoadable
    
    let countryName: String
    let dateRangeText: String
    
    init(album: Album, imageLoader: any ImageLoadable) {
        self.id = album.id
        self.localIdentifier = album.coverPhotoIdentifier ?? ""
        self.displayName = album.displayName.replacingOccurrences(of: "_", with: " ")
        self.formattedDate = ""
        self.photoCount = album.photoCount
        self.album = album
        self.imageLoader = imageLoader
        
        self.countryName = ""

        let formatter = DateIntervalFormatter()
        formatter.locale = Locale(identifier: "ko")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        self.dateRangeText = formatter.string(
            from: album.startDate,
            to: album.endDate)
    }
}
