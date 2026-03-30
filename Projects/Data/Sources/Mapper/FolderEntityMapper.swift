//
//  FolderEntityMapper.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension FolderEntity {
    func toDomain() -> Folder {
        Folder(
            id: id,
            name: name,
            displayName: displayName,
            createdAt: createdAt,
            isAuto: isAuto,
            coverPhotoIdentifier: coverPhotoIdentifier,
            keywords: keywords.map { $0.keyword },
            photos: photos.sorted { $0.createdAt > $1.createdAt} .prefix(4).map {$0.toDomain()},
            photoCount: photoCount
        )
    }
}
