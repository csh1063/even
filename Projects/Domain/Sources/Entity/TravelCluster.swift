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
    public let startDate: Date
    public let endDate: Date
    
    public var folderName: String {
        let place = locality ?? administrativeArea
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return "\(place) · \(formatter.string(from: startDate))"
    }
    
    public var folderDisplayName: String { folderName }
    
    public init(photos: [PhotoLocationSnapshot],
                country: String,
                administrativeArea: String,
                locality: String?,
                startDate: Date,
                endDate: Date) {
        self.photos = photos
        self.country = country
        self.administrativeArea = administrativeArea
        self.locality = locality
        self.startDate = startDate
        self.endDate = endDate
    }
}
