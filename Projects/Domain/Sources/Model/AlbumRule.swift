//
//  AlbumRule.swift
//  Domain
//
//  Created by sanghyeon on 5/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

struct LabelFilter: Decodable {
    let name: String
    let min: Float?
    let max: Float?
}

public struct AlbumRule: Decodable {
    let type: String
    let minConfidence: Float
    let matchTags: [String]
    let excludeTags: [String]
    let mustHaveOneOf: [String]?
    let labelFilters: [LabelFilter]?

    enum CodingKeys: String, CodingKey {
        case type
        case minConfidence = "min_confidence"
        case matchTags = "match_tags"
        case excludeTags = "exclude_tags"
        case mustHaveOneOf = "must_have_one_of"
        case labelFilters = "label_filters"
    }
}
