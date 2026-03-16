//
//  Tag.swift
//  Domain
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public enum TagType: String {
    case object
    case scene
    case food
    case animal
    case text
    case face
}

public enum TagNormalizer {

    public static func normalize(_ text: String) -> String {
        text
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
}

public struct Tag: Equatable, Hashable {

    public let id: UUID
    public let name: String
    public let nameNormalized: String

    public init(
        id: UUID = UUID(),
        name: String,
        nameNormalized: String
    ) {
        self.id = id
        self.name = name
        self.nameNormalized = nameNormalized
    }
}


