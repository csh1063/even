//
//  HomeZoneEntityMapper.swift
//  Data
//
//  Created by sanghyeon on 5/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension HomeZoneEntity {
    func toDomain() -> HomeZone {
        HomeZone(latitude: latitude,
                 longitude: longitude,
                 analyzedAt: analyzedAt)
    }
}
