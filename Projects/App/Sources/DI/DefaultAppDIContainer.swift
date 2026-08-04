//
//  DefaultAppDIContainer.swift
//  App
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Presentation
import Data
import Domain
import SwiftData

@MainActor
final class DefaultAppDIContainer: AppDIContainer {

    let container: ModelContainer

    var photoLibraryRepository: PhotoLibraryRepository {
        repositoryFactory.photoLibraryRepository
    }

    var photoAnalysisRepository: PhotoAnalysisRepository {
        repositoryFactory.photoAnalysisRepository
    }

    var photoDataRepository: PhotoDataRepository {
        repositoryFactory.photoDataRepository
    }

    var albumDataRepository: AlbumDataRepository {
        repositoryFactory.albumDataRepository
    }

    var photoLabelDataRepository: PhotoLabelDataRepository {
        repositoryFactory.photoLabelDataRepository
    }

    var photoCategoryRepository: PhotoCategoryRepository {
        repositoryFactory.photoCategoryRepository
    }

    var geoRepository: GeoRepository {
        repositoryFactory.geoRepository
    }

    var userDefaultRepository: UserDefaultRepository {
        repositoryFactory.userDefaultRepository
    }

    var permissionRepository: PermissionRepository {
        repositoryFactory.permissionRepository
    }

    var settingsRepository: SettingsRepository {
        repositoryFactory.settingsRepository
    }

    var travelRepository: TravelDetectionRepository {
        repositoryFactory.travelRepository
    }

    var homeZoneRepository: HomeZoneRepository {
        repositoryFactory.homeZoneRepository
    }

    var faceClusterRepository: FaceClusterRepository {
        repositoryFactory.faceClusterRepository
    }

    var animalClusterRepository: AnimalClusterRepository {
        repositoryFactory.animalClusterRepository
    }

    var similarRepository: SimilarPhotoClusterRepository {
        repositoryFactory.similarRepository
    }

    var remoteConfigRepository: RemoteConfigRepository {
        repositoryFactory.remoteConfigRepository
    }

    var legacyAccessRepository: LegacyAccessRepository {
        repositoryFactory.legacyAccessRepository
    }

    private let providerFactory: ProviderFactory
    private lazy var executor: NetworkExecutor = {
        DefaultNetworkExecutor(providerFactory: providerFactory)
    }()

    private lazy var serviceFactory = ServiceFactory(executor: executor)
    private lazy var repositoryFactory = RepositoryFactory(
        container: container,
        serviceFactory: serviceFactory
    )

    init() {
        do {
            container = try ModelContainer(
                for: Schema(MoaSchemaV0.models, version: MoaSchemaV0.versionIdentifier),
                migrationPlan: MoaSchemaMigrationPlan.self
            )
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
        self.providerFactory = ProviderFactory()

        Task {
            self.albumDataRepository.pruneOldHistory()
        }
    }

    func makePhotoCheckUseCase() -> PhotoCheckUseCase {
        DefaultPhotoCheckUseCase(photoLibraryRepository: photoLibraryRepository,
                                 photoDataRepository: photoDataRepository,
                                 albumDataRepository: albumDataRepository
        )
    }

    func makeAppVersionCheckUseCase() -> AppVersionCheckUseCase {
        DefaultAppVersionCheckUseCase(repository: remoteConfigRepository)
    }

    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel(
            useCase: makePhotoCheckUseCase(),
            versionCheckUseCase: makeAppVersionCheckUseCase()
        )
    }

    func makeMainUseCase() {

    }
}
