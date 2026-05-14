//
//  PermissionRepository.swift
//  Domain
//
//  Created by sanghyeon on 5/14/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PermissionRepository {
    func checkPermission() async throws -> PhotoPermission
}
