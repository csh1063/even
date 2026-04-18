//
//  PhotoModel.swift
//  Data
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Photos

public struct AlbumAssetEntity {
    let name: String
    let count: Int
    let collection: PHAssetCollection?
}

public struct PhotoAssetEntity {
    let asset: PHAsset
}

public struct PhotoAssetListEntity {
    let title: String
    let photos: [PhotoAssetEntity]
    let hasNext: Bool
}
