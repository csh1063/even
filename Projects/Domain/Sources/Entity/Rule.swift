//
//  Rule.swift
//  Domain
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public enum RuleType: String {
    case tag
    case date
    case location
    case text
    case face
}

public enum RuleComparison: String {
    case contains
    case equals
    case between
    case near
}

public struct Rule {
    
    let id: UUID
    let type: RuleType
    let comparison: RuleComparison
    let value: String
    
    public init(id: UUID, type: RuleType, comparison: RuleComparison, value: String) {
        self.id = id
        self.type = type
        self.comparison = comparison
        self.value = value
    }
}

struct DateRulePayload: Codable {
    let start: Date
    let end: Date
}

struct TagRulePayload: Codable {
    let keywordNormalized: String
}

struct LocationRulePayload: Codable {
    let addressNormalized: String
}

struct TextRulePayload: Codable {
    let keywordNormalized: String
}

struct FaceRulePayload: Codable {
    let personIdentifier: String
}
