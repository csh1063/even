//
//  Photo.swift
//  Domain
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct Photo: Hashable {
    public let id: UUID
    public let localIdentifier: String
    public let createdAt: Date
    public var analyzedAt: Date?
    
    // address
    public var latitude: Double?
    public var longitude: Double?
    public var isoCountryCode: String?
    public var address: PhotoLocation?
    public var addressEn: PhotoLocation?
    
//    public var country: String? {
//        return address?.country
//    }
//    public var locality: String? {
//        return address?.locality
//    }
//    public var administrativeArea: String? {
//        return address?.administrativeArea
//    }
    
    // date
    public var year: String?
    public var month: String?
    
    public var labels: [PhotoLabel]
    public var faceEmbedding: [FaceEmbedding]
    
    public init(
        id: UUID = UUID(),
        localIdentifier: String,
        createdAt: Date = Date(),
        analyzedAt: Date? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isoCountryCode: String? = nil,
        address: PhotoLocation? = nil,
        addressEn: PhotoLocation? = nil,
        year: String? = nil,
        month: String? = nil,
        labels: [PhotoLabel] = [],
        faceEmbedding: [FaceEmbedding] = []
    ) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.createdAt = createdAt
        self.analyzedAt = analyzedAt
        self.latitude = latitude
        self.longitude = longitude
        self.isoCountryCode = isoCountryCode
        self.address = address
        self.addressEn = addressEn
        self.year = year
        self.month = month
        self.labels = labels
        self.faceEmbedding = faceEmbedding
    }
    
    public static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }
}

extension String {
    func toDate(format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: self)
    }
}
