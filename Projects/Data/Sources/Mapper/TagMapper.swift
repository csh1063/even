//
//  TagMapper.swift
//  Data
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension TagEntity {
    func toDomain() -> Tag {
        Tag(id: id ?? UUID(),
            name: name ?? "",
            nameNormalized: nameNormalized ?? "")
    }
    
    func update(from tag: Tag) {
        id = tag.id
        name = tag.name
        nameNormalized = TagNormalizer.normalize(tag.name)
    }
}
