//
//  PhotoDetail.swift
//  Domain
//
//  Created by sanghyeon on 5/8/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct PhotoDetail {
    public let id: String
    public let photo: Photo?
    
    public init(id: String, photo: Photo? = nil) {
        self.id = id
        self.photo = photo
    }
}
