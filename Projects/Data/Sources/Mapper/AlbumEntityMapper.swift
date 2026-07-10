//
//  AlbumEntityMapper.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension AlbumEntity {
    func toDomain() -> Album {
        Album(
            id: id,
            name: name,
            displayName: displayName,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            isAuto: isAuto,
            coverPhotoIdentifier: coverPhotoIdentifier,
            keywords: [],
            photos: [],
            photoCount: photoCount,
            from: from,
            clusterId: clusters.map { $0.id.uuidString }
        )
    }

    func toDomainWithKey() -> Album {
        Album(
            id: id,
            name: name,
            displayName: displayName,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            isAuto: isAuto,
            coverPhotoIdentifier: coverPhotoIdentifier,
            keywords: keywords.map { $0.keyword },
            photos: [],
            photoCount: photoCount,
            from: from
        )
    }

    func toDomainWithPhoto() -> Album {
        Album(
            id: id,
            name: name,
            displayName: displayName,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            isAuto: isAuto,
            coverPhotoIdentifier: coverPhotoIdentifier,
            keywords: [],
            photos: photos.sorted { $0.createdAt > $1.createdAt }.prefix(4).map { $0.toDomain() },
            photoCount: photoCount,
            from: from
        )
    }

    func toDomainAll() -> Album {
        Album(
            id: id,
            name: name,
            displayName: displayName,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            isAuto: isAuto,
            coverPhotoIdentifier: coverPhotoIdentifier,
            keywords: keywords.map { $0.keyword },
            photos: photos.sorted { $0.createdAt > $1.createdAt }.prefix(4).map { $0.toDomain() },
            photoCount: photoCount,
            from: from
        )
    }
}
