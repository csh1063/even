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
            isoCountryCode: isoCountryCode,
            address: address,
            addressEn: addressEn,
            year: year,
            month: month,
            labels: [],
            faceEmbedding: []
        )
    }

    func toDomainWithLabels() -> Photo {
        return Photo(
            id: id,
            localIdentifier: localIdentifier,
            createdAt: createdAt,
            analyzedAt: analyzedAt,
            latitude: latitude,
            longitude: longitude,
            isoCountryCode: isoCountryCode,
            address: address,
            addressEn: addressEn,
            year: year,
            month: month,
            labels: labels.map { $0.toDomain() },
            faceEmbedding: []
        )
    }

    func toDomainWithEmbedding() -> Photo {
        return Photo(
            id: id,
            localIdentifier: localIdentifier,
            createdAt: createdAt,
            analyzedAt: analyzedAt,
            latitude: latitude,
            longitude: longitude,
            isoCountryCode: isoCountryCode,
            address: address,
            addressEn: addressEn,
            year: year,
            month: month,
            labels: [],
            faceEmbedding: faceEmbeddings.map { $0.toDomain() }
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
            isoCountryCode: isoCountryCode,
            address: address,
            addressEn: addressEn,
            year: year,
            month: month,
            labels: labels.map { $0.toDomain() },
            faceEmbedding: faceEmbeddings.map { $0.toDomain() }
        )
    }
}
