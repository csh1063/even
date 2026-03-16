//
//  PhotoModel.swift
//  Data
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Photos

public struct AlbumModel {
    let name: String
    let count: Int
    let collection: PHAssetCollection?
}

public struct PhotoModel {
    let asset: PHAsset
}

public struct PhotoListModel {
    let title: String
    let photos: [PhotoModel]
    let hasNext: Bool
}
