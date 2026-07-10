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
    public let isoCountryCode: String?
    public let country: String?
    public let administrativeArea: String?
    public let locality: String?
    public var subLocality: String?
    public let latitude: Double
    public let longitude: Double

    public init(from photo: Photo) {
        self.localIdentifier = photo.localIdentifier
        self.createdAt = photo.createdAt
        self.isoCountryCode = photo.isoCountryCode
        self.country = photo.address?.country
        self.administrativeArea = photo.address?.administrativeArea
        self.locality = photo.address?.locality
        self.subLocality = photo.address?.subLocality
        self.latitude = photo.latitude ?? 0
        self.longitude = photo.longitude ?? 0
    }
}
