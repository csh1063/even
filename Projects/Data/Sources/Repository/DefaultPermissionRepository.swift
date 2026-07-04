//
//  DefaultPermissionRepository.swift
//  Data
//
//  Created by sanghyeon on 5/14/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

public final class DefaultPermissionRepository: PermissionRepository {

    private let service: PermissionService

    init(service: PermissionService) {
        self.service = service
    }

    public func checkPermission() async throws -> PhotoPermission {
        try await service.checkPermission()
    }
}
