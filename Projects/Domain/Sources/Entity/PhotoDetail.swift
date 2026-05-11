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
    public let createdDate: Date?
    public let photo: Photo?
    public var labels: [PhotoLabel] = []
    
    public init(id: String, createdDate: Date?, photo: Photo? = nil) {
        self.id = id
        self.createdDate = createdDate
        self.photo = photo
    }
}
