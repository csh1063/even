//
//  PhotoModelMapper.swift
//  Data
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension AlbumModel {
    func toDomain() -> Album {
        return Album(
            name: self.name,
            count: self.count,
            collection: self.collection)
    }
}

extension PhotoModel {
    func toDomain() -> PhotoInAlbum {
        return PhotoInAlbum(
            id: self.asset.localIdentifier
        )
    }
}

extension PhotoListModel {
    func toDomain() -> PhotoList {
        return PhotoList(
            title: self.title,
            photos: self.photos.map {$0.toDomain()},
            hasNext: self.hasNext)
    }
}
