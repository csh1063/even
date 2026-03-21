//
//  Album.swift
//  Domain
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Photos

public struct Album {

    public let name: String
    public let count: Int
    public var collection: PHAssetCollection?
//    public var thumbnailImage: UIImage?

    public init(name: String, count: Int, collection: PHAssetCollection?) {
        self.name = name
        self.count = count
        self.collection = collection
    }
}
