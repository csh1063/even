//
//  TravelCluster.swift
//  Domain
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct TravelCluster {
    public let photos: [PhotoLocationSnapshot]
    public let country: String
    public let administrativeArea: String
    public let locality: String?
    public let subLocality: String?
    public let isoCountryCode: String
    public let startDate: Date
    public let endDate: Date
    
    public var address: String {
        return locality?.isEmpty == false ? locality! :
        administrativeArea.isEmpty ? country :
        administrativeArea
    }

    public init(
        photos: [PhotoLocationSnapshot],
        country: String,
        administrativeArea: String,
        locality: String?,
        subLocality: String?,
        isoCountryCode: String,
        startDate: Date,
        endDate: Date
    ) {
        self.photos = photos
        self.country = country
        self.administrativeArea = administrativeArea
        self.locality = locality
        self.subLocality = subLocality
        self.isoCountryCode = isoCountryCode
        self.startDate = startDate
        self.endDate = endDate
    }
}
