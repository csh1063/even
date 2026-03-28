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
    
    public var photoLibraryService: PhotoLibraryService = {
        PhotoLibraryService()
    }()
    
    public var permissionService: PermissionService = {
        PermissionService()
    }()
    
    public var photoAnalysisService: PhotoAnalysisService = {
        PhotoAnalysisService()
    }()
    
    public var geocoderService: GeocoderService = {
        GeocoderService()
    }()
}
