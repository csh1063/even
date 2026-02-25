//
//  RuleMapper.swift
//  Data
//
//  Created by sanghyeon on 2/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension RuleEntity {
    func toDomain() -> Rule {
        guard let id,
              let typeString = type,
              let comparisonString = comparison,
              let ruleType = RuleType(rawValue: typeString),
              let ruleComparison = RuleComparison(rawValue: comparisonString) else {
            fatalError("Invalid RuleEntity state")
        }

        return Rule(
            id: id,
            type: ruleType,
            comparison: ruleComparison,
            value: value ?? ""
        )
    }
}
