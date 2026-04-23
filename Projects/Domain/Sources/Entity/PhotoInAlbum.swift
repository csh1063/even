//
//  PhotoInAlbum.swift
//  Domain
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

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
//    public var cropInfo: CropInfo?
    public let createdDate: Date?
    
    public init(id: String, createdDate: Date? = nil) {
        self.localIdentifier = id
        self.createdDate = createdDate
    }
}

public class CropInfo: NSObject {
    let pos: CGPoint
    let scale: CGFloat
    
    init(pos: CGPoint, scale: CGFloat) {
        self.pos = pos
        self.scale = scale
    }
}
