//
//  ServiceFactory.swift
//  Data
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


//
//  ServiceFactory.swift
//  Data
//
//  Created by sanghyeon on 12/11/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

public final class ServiceFactory {

    public init() {
    }
    
    
    public func makePhotoLibraryService() -> PhotoLibraryService {
        PhotoLibraryService()
    }
    
    public func makePermissionService() -> PermissionService {
        PermissionService()
    }
    
    public func makePhotoAnalysisService() -> PhotoAnalysisService {
        PhotoAnalysisService()
    }
    
    public func makeGeocoderService() -> GeocoderService {
        GeocoderService()
    }
}
