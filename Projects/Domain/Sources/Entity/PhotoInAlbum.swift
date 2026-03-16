//
//  PhotoInAlbum.swift
//  Domain
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Foundation
//import Photos

public enum LoadPhotoOptionType {
    case maxSize
    case specialSize(CGSize)
}

public enum PhotoPermission {
    case fullAccess    // authorized
    case limitedAccess // limited
    case denied        // denied, restricted
    case notDetermined
    
    public var access: Bool {
        return self == .fullAccess || self == .limitedAccess
    }
}

public struct PhotoList {
    public let title: String
    public let photos: [PhotoInAlbum]
    public let hasNext: Bool
    
    public init(title: String, photos: [PhotoInAlbum], hasNext: Bool) {
        self.title = title
        self.photos = photos
        self.hasNext = hasNext
    }
}

public struct PhotoInAlbum: Hashable {
    
    public let localIdentifier: String
//    public let asset: PHAsset
    
    public var cellImage: UIImage?
    
    public var largeImage: UIImage?
    public var cropedImage: UIImage?
    public var cropInfo: CropInfo?
    
    public init(id: String) {
        self.localIdentifier = id
//        self.asset = asset
    }
//    public init(asset: PHAsset) {
//        self.localIdentifier = asset.localIdentifier
//        self.asset = asset
//    }
    
//    public func loadCellSizeImage(size: CGSize, done: @escaping (UIImage?) -> Void) {
//        self.loadImage(type: .specialSize(size)) { image in
//            done(image)
//        }
//    }
//    
//    public func loadFullSizeImage(done: @escaping (UIImage?) -> Void) {
//        self.loadImage(type: .maxSize) { image in
//            self.largeImage = image
//            done(image)
//        }
//    }
//    
//    private func loadImage(type: LoadPhotoOptionType, done: @escaping (UIImage?) -> Void) {
//        guard let asset = asset else { return }
//        
//        let options = PHImageRequestOptions()
//        let size: CGSize
//        let contentMode: PHImageContentMode
//        switch type {
//        case .maxSize:
//            options.deliveryMode = .highQualityFormat
//            options.resizeMode = .exact
//            options.isSynchronous = false
//            options.isNetworkAccessAllowed = true
//            size = PHImageManagerMaximumSize
//            contentMode = .default
//        case .specialSize(let specialSize):
//            options.resizeMode = .fast
//            options.deliveryMode = .opportunistic
//            options.isSynchronous = false
//            options.isNetworkAccessAllowed = false
//            size = specialSize
//            contentMode = .aspectFill
//        }
//        
//        PHImageManager.default().requestImage(for: asset, targetSize: size,
//                             contentMode: contentMode, options: options) { (result, _) in
//                                done(result)
//        }
//    }
}

public class CropInfo: NSObject {
    let pos: CGPoint
    let scale: CGFloat
    
    init(pos: CGPoint, scale: CGFloat) {
        self.pos = pos
        self.scale = scale
    }
}
