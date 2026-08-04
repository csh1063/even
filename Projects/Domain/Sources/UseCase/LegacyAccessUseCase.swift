//
//  LegacyAccessUseCase.swift
//  Domain
//
//  Created by sanghyeon on 8/4/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol LegacyAccessUseCase {
    func markLegacyFreeAccess() async throws
    func hasLegacyFreeAccess() async throws -> Bool
}

public final class DefaultLegacyAccessUseCase: LegacyAccessUseCase {

    private let repository: LegacyAccessRepository

    public init(repository: LegacyAccessRepository) {
        self.repository = repository
    }

    public func markLegacyFreeAccess() async throws {
        try await repository.markLegacyFreeAccess()
    }

    public func hasLegacyFreeAccess() async throws -> Bool {
        try await repository.hasLegacyFreeAccess()
    }
}
