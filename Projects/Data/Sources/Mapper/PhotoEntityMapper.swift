//
//  PhotoEntityMapper.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension PhotoEntity {
    func toDomain() -> Photo {
        return Photo(
            id: id,
            localIdentifier: localIdentifier,
            createdAt: createdAt,
            analyzedAt: analyzedAt,
            latitude: latitude,
            longitude: longitude,
            address: address,
            addressEn: addressEn,
            year: year,
            month: month,
            labels: []
        )
    }
    
    func toDomainAll() -> Photo {
        return Photo(
            id: id,
            localIdentifier: localIdentifier,
            createdAt: createdAt,
            analyzedAt: analyzedAt,
            latitude: latitude,
            longitude: longitude,
            address: address,
            addressEn: addressEn,
            year: year,
            month: month,
            labels: labels.map { $0.toDomain() }
        )
    }
}
