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

    private let executor: NetworkExecutor

    public init(executor: NetworkExecutor) {
        self.executor = executor
    }

    public lazy var networkService: NetworkService = {
        NetworkService(excuteor: self.executor)
    }()

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

    public var photoCategoryService: PhotoCategoryService = {
        PhotoCategoryService()
    }()

    public var userDefaultsService: UserDefaultsService = {
        UserDefaultsService()
    }()

    public var faceEmbeddingService: FaceEmbeddingService = {
        FaceEmbeddingService()
    }()

    public lazy var faceClusterService: FaceClusterService = {
        FaceClusterService(libraryService: photoLibraryService)
    }()

    public var animalEmbeddingService: AnimalEmbeddingService = {
        AnimalEmbeddingService()
    }()

    public lazy var animalClusterService: AnimalClusterService = {
        AnimalClusterService()
    }()

    public lazy var similarService: SimilarPhotoClusterService = {
        SimilarPhotoClusterService()
    }()
}
