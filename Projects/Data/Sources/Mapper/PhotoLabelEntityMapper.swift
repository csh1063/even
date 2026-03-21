//
//  PhotoLabelEntityMapper.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension PhotoLabelEntity {
    func toDomain() -> PhotoLabel {
        PhotoLabel(
            name: name,
            confidence: confidence
        )
    }
}
