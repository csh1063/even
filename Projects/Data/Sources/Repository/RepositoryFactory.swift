//
//  RepositoryFactory.swift
//  Data
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import SwiftData

public final class RepositoryFactory {

    private let container: ModelContainer
    private let serviceFactory: ServiceFactory

    public init(container: ModelContainer, serviceFactory: ServiceFactory) {
        self.container = container
        self.serviceFactory = serviceFactory
    }

    public lazy var photoLibraryRepository: PhotoLibraryRepository = {
        DefaultPhotoLibraryRepository(
            libraryService: serviceFactory.photoLibraryService,
            permissionService: serviceFactory.permissionService
        )
    }()

    public lazy var photoAnalysisRepository: PhotoAnalysisRepository = {
        DefaultPhotoAnalysisRepository(
            analysisService: serviceFactory.photoAnalysisService,
            libraryService: serviceFactory.photoLibraryService,
            geocoderService: serviceFactory.geocoderService,
            networkService: serviceFactory.networkService,
            faceEmbeddingService: serviceFactory.faceEmbeddingService,
            animalEmbeddingService: serviceFactory.animalEmbeddingService
        )
    }()

    public lazy var photoDataRepository: PhotoDataRepository = {
        DefaultPhotoDataRepository(container: container)
    }()

    public lazy var albumDataRepository: AlbumDataRepository = {
        DefaultAlbumDataRepository(container: container)
    }()

    public lazy var photoLabelDataRepository: PhotoLabelDataRepository = {
        DefaultPhotoLabelDataRepository(container: container)
    }()

    public lazy var photoCategoryRepository: PhotoCategoryRepository = {
        DefaultPhotoCategoryRepository(service: serviceFactory.photoCategoryService)
    }()

    public lazy var geoRepository: GeoRepository = {
        DefaultGeoRepository(service: serviceFactory.networkService)
    }()

    public lazy var userDefaultRepository: UserDefaultRepository = {
        DefaultUserDefaultRepository(service: serviceFactory.userDefaultsService)
    }()

    public lazy var permissionRepository: PermissionRepository = {
        DefaultPermissionRepository(service: serviceFactory.permissionService)
    }()

    public lazy var settingsRepository: SettingsRepository = {
        DefaultSettingsRepository(service: serviceFactory.networkService)
    }()

    public lazy var faceClusterRepository: FaceClusterRepository = {
        DefaultFaceClusterRepository(
            container: container,
            clusterService: serviceFactory.faceClusterService)
    }()

    public lazy var animalClusterRepository: AnimalClusterRepository = {
        DefaultAnimalClusterRepository(
            container: container,
            clusterService: serviceFactory.animalClusterService)
    }()

    public lazy var travelRepository: TravelDetectionRepository = {
        DefaultTravelDetectionRepository(
            geocoderService: serviceFactory.geocoderService
        )
    }()

    public lazy var homeZoneRepository: HomeZoneRepository = {
        DefaultHomeZoneRepository(container: container)
    }()

    public lazy var similarRepository: SimilarPhotoClusterRepository = {
        DefaultSimilarPhotoClusterRepository(container: container)
    }()

    public lazy var remoteConfigRepository: RemoteConfigRepository = {
        DefaultRemoteConfigRepository(service: serviceFactory.remoteConfigService)
    }()
}
