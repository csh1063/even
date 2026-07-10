//
//  HomeZoneEntity.swift
//  Data
//
//  Created by sanghyeon on 5/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class HomeZoneEntity {
    public var latitude: Double
    public var longitude: Double
    public var analyzedAt: Date

    public init(latitude: Double, longitude: Double, analyzedAt: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.analyzedAt = analyzedAt
    }
}
