//
//  TabbarDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class TabbarDIContainer {

    private let appDiContainer: AppDIContainer

    public init(appDiContainer: AppDIContainer) {
        self.appDiContainer = appDiContainer
    }

    func makeTabbarViewModel() -> TabbarViewModel {

        let permissionUseCase = DefaultPermissionUseCase(
            permissionRepository: appDiContainer.permissionRepository,
            userDefaultRepository: appDiContainer.userDefaultRepository
        )

        let analysisUseCase = DefaultPhotoAnalysisUseCase(
            libraryRepository: appDiContainer.photoLibraryRepository,
            analysisRepository: appDiContainer.photoAnalysisRepository,
            dataRepository: appDiContainer.photoDataRepository,
            geoRepository: appDiContainer.geoRepository
        )

        let autoAlbumUseCase = DefaultAutoAlbumUseCase(
            photoDataRepository: appDiContainer.photoDataRepository,
            albumDataRepository: appDiContainer.albumDataRepository,
            photoCategoryRepository: appDiContainer.photoCategoryRepository,
            userDefaultRepository: appDiContainer.userDefaultRepository,
            travelRepository: appDiContainer.travelRepository,
            homeZoneRepository: appDiContainer.homeZoneRepository,
            faceClusterRepository: appDiContainer.faceClusterRepository,
            animalClusterRepository: appDiContainer.animalClusterRepository,
            similarRepository: appDiContainer.similarRepository
        )

        return TabbarViewModel(permissionUseCase: permissionUseCase,
                               analysisUseCase: analysisUseCase,
                               autoAlbumUseCase: autoAlbumUseCase)
    }

    func makePhotoLibraryDIContainer() -> PhotoLibraryDIContainer {
        PhotoLibraryDIContainer(
            photoLibraryRepository: appDiContainer.photoLibraryRepository,
            photoDataRepository: appDiContainer.photoDataRepository,
            labelDataRepository: appDiContainer.photoLabelDataRepository
        )
    }

    func makeAlbumDIContainer() -> AlbumDIContainer {
        AlbumDIContainer(appDIContainer: appDiContainer)
    }

    func makeMyPageDIContainer() -> MyPageDIContainer {
        MyPageDIContainer(appDIContainer: appDiContainer)
    }
}
