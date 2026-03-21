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
        Photo(
            id: id,
            localIdentifier: localIdentifier,
            createdAt: createdAt,
            analyzedAt: analyzedAt,
            labels: labels.map { $0.toDomain() }
        )
    }
}
