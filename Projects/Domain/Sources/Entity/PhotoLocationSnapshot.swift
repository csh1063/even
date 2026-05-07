//
//  PhotoLocationSnapshot.swift
//  Domain
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct PhotoLocationSnapshot {
    public let localIdentifier: String
    public let createdAt: Date
    public let country: String?
    public let administrativeArea: String?
    public let locality: String?
    
    public init(from photo: Photo) {
        self.localIdentifier = photo.localIdentifier
        self.createdAt = photo.createdAt
        self.country = photo.country
        self.administrativeArea = photo.administrativeArea
        self.locality = photo.locality
    }
}
