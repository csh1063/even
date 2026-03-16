//
//  Album.swift
//  Domain
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Photos
import UIKit

public struct Album {

    public let name: String
    public let count: Int
    public var collection: PHAssetCollection?
    public var thumbnailImage: UIImage?

    public init(name: String, count: Int, collection: PHAssetCollection?) {
        self.name = name
        self.count = count
        self.collection = collection

//        let opt = PHFetchOptions()
//        if let firstAsset = PHAsset.fetchAssets(in: collection, options: opt).lastObject {
//            let manager = PHImageManager.default()
//            let option = PHImageRequestOptions()
//            option.isSynchronous = true
//            let size = CGSize(width: 160, height: 160)
//            manager.requestImage(for: firstAsset, targetSize: size, contentMode: .default,
//                                 options: option, resultHandler: { (result, _) in
//                if let image = result {
//                    self.thumbnailImage = image
//                }
//            })
//        }
    }
}
