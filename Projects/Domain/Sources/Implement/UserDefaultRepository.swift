//
//  UserDefaultRepository.swift
//  Domain
//
//  Created by sanghyeon on 5/1/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol UserDefaultRepository {
    func saveAnalyzedDate() async throws
    func fetchAnalyzedDate() async throws -> String
    func saveDisplayMode(_ mode: String) async throws
    func fetchDisplayMode() async throws -> String
    func saveAutoNewAnalysis(isOn: Bool) async throws
    func fetchAutoNewAnalysis() async throws -> Bool?
}
