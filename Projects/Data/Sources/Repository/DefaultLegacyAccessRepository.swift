//
//  DefaultLegacyAccessRepository.swift
//  Data
//
//  Created by sanghyeon on 8/4/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

public final class DefaultLegacyAccessRepository: LegacyAccessRepository {

    private static let key = "com.baci.moa.legacyFreeAccess"

    private let service: KeychainService

    public init(service: KeychainService) {
        self.service = service
    }

    public func markLegacyFreeAccess() async throws {
        guard service.string(forKey: Self.key) == nil else { return }
        service.set(ISO8601DateFormatter().string(from: Date()), forKey: Self.key)
    }

    public func hasLegacyFreeAccess() async throws -> Bool {
        service.string(forKey: Self.key) != nil
    }
}
