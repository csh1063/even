//
//  RemoteConfigRepository.swift
//  Domain
//
//  Created by sanghyeon on 8/3/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol RemoteConfigRepository {
    func fetchVersionPolicy() async throws -> AppVersionPolicy
}
