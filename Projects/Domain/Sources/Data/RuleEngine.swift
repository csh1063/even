//
//  RuleEngine.swift
//  Domain
//
//  Created by sanghyeon on 2/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public final class RuleEngine {

    private let decoder: JSONDecoder

    public init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

//    public func matches(photo: Photo, rules: [Rule]) -> Bool {
//        rules.allSatisfy { evaluate(photo: photo, rule: $0) }
//    }

//    private func evaluate(photo: Photo, rule: Rule) -> Bool {
//        guard let data = rule.value.data(using: .utf8) else { return false }
//
//        switch rule.type {
//
//        case .date:
//            guard
//                let payload = try? decoder.decode(DateRulePayload.self, from: data)
//            else { return false }
//
//            // takenDate 없음 → false
//            return false
//
//        case .tag:
//            guard let payload = try? decoder.decode(TagRulePayload.self, from: data) else { return false }
//
//            switch rule.comparison {
//            case .contains:
//                return photo.tags.contains { $0.nameNormalized.contains(payload.keywordNormalized) }
//            case .equals:
//                return photo.tags.contains { $0.nameNormalized == payload.keywordNormalized }
//            default:
//                return false
//            }
//
//        case .location:
//            // address 없음 → false
//            return false
//
//        default:
//            return false
//        }
//    }
}
