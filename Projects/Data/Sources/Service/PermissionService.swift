//
//  PermissionService.swift
//  Data
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import Photos

public final class PermissionService {
    
    public init() {}
    
    public func checkPermission() async throws -> PhotoPermission {
        
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized: return .fullAccess
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            switch newStatus {
            case .authorized: return .fullAccess
            case .limited: return .limitedAccess
            case .notDetermined: return .notDetermined
            default: return .denied
            }
        case .limited: return .limitedAccess
        default: return .denied
        }
    }
    
}
