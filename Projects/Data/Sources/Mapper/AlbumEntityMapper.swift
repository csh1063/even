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
            coverPhotoManuallySet: coverPhotoManuallySet,
            keywords: [],
            photos: [],
            photoCount: photoCount,
            from: from,
            isEdited: isEdited,
            isRenamed: isRenamed,
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
            coverPhotoManuallySet: coverPhotoManuallySet,
            keywords: keywords.map { $0.keyword },
            photos: [],
            photoCount: photoCount,
            from: from,
            isEdited: isEdited,
            isRenamed: isRenamed
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
            coverPhotoManuallySet: coverPhotoManuallySet,
            keywords: [],
            photos: photos.sorted { $0.createdAt > $1.createdAt }.prefix(4).map { $0.toDomain() },
            photoCount: photoCount,
            from: from,
            isEdited: isEdited,
            isRenamed: isRenamed
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
            coverPhotoManuallySet: coverPhotoManuallySet,
            keywords: keywords.map { $0.keyword },
            photos: photos.sorted { $0.createdAt > $1.createdAt }.prefix(4).map { $0.toDomain() },
            photoCount: photoCount,
            from: from,
            isEdited: isEdited,
            isRenamed: isRenamed
        )
    }
}
