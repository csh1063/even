//
//  RuleRepository.swift
//  Domain
//
//  Created by sanghyeon on 2/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol RuleRepository {

    func create(
        folderID: UUID,
        type: RuleType,
        comparison: RuleComparison,
        value: String
    ) async throws -> Rule
    func fetchRules(folderID: UUID) async throws -> [Rule]
    func delete(ruleID: UUID) async throws
}
