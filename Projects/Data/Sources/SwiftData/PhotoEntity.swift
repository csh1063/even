//
//  PhotoEntity.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation
import Domain

@Model
public final class PhotoEntity {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var localIdentifier: String
    public var createdAt: Date
    public var analyzedAt: Date?
    public var locationAnalyzedAt: Date?
    
    public var latitude: Double?
    public var longitude: Double?
    
    // address
    public var isoCountryCode: String?
    public var address: PhotoLocation?
    public var addressEn: PhotoLocation?
    
    // date
    public var year: String?
    public var month: String?
    
    @Relationship(deleteRule: .cascade)
    public var labels: [PhotoLabelEntity] = []
    
    @Relationship(deleteRule: .nullify, inverse: \FolderEntity.photos)
    public var folders: [FolderEntity] = []
    
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
        month: String? = nil
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
    }
}
