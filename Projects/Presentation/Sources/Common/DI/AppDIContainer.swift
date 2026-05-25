//
//  AppDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public protocol AppDIContainer {
    
    var photoLibraryRepository: PhotoLibraryRepository {get}
    var photoAnalysisRepository: PhotoAnalysisRepository {get}
    var photoDataRepository: PhotoDataRepository {get}
    var folderDataRepository: FolderDataRepository {get}
    var photoLabelDataRepository: PhotoLabelDataRepository {get}
    var photoCategoryRepository: PhotoCategoryRepository {get}
    var geoRepository: GeoRepository {get}
    var userDefaultRepository: UserDefaultRepository {get}
    var permissionRepository: PermissionRepository {get}
    var settingsRepository: SettingsRepository {get}
    var travelRepository: TravelDetectionRepository {get}
    var homeZoneRepository: HomeZoneRepository {get}
    var faceClusterRepository: FaceClusterRepository {get}
    
    func makeSplashViewModel() -> SplashViewModel
    func makeMainViewModel() -> MainViewModel
}

