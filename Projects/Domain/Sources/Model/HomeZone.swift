//
//  HomeZone.swift
//  Domain
//
//  Created by sanghyeon on 5/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

// Domain 모듈
public struct HomeZone {
    public let latitude: Double
    public let longitude: Double
    public let analyzedAt: Date

    public init(latitude: Double, longitude: Double, analyzedAt: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.analyzedAt = analyzedAt
    }
}
