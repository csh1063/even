//
//  DefaultRemoteConfigRepository.swift
//  Data
//
//  Created by sanghyeon on 8/3/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

public final class DefaultRemoteConfigRepository: RemoteConfigRepository {

    private let service: RemoteConfigService

    public init(service: RemoteConfigService) {
        self.service = service
    }

    public func fetchVersionPolicy() async throws -> AppVersionPolicy {
        let (min, recommend) = try await service.fetchMinAndRecommendVersion()
        debugLog("min: \(min), recomment: \(recommend)")
        return AppVersionPolicy(minVersion: min, recommendVersion: recommend)
    }
}
