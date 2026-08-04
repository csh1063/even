//
//  LegacyAccessRepository.swift
//  Domain
//
//  Created by sanghyeon on 8/4/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol LegacyAccessRepository {
    func markLegacyFreeAccess() async throws
    func hasLegacyFreeAccess() async throws -> Bool
}
