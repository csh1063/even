//
//  MyPageDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 1/5/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

@MainActor
public final class MyPageDIContainer {

    let appDIContainer: AppDIContainer

    public init(appDIContainer: AppDIContainer) {
        self.appDIContainer = appDIContainer
    }

    func makeMyPageViewModel(coordinator: MyPageCoordinator) -> MyPageViewModel {
//        let service = Tab1Service(
//            provider: appDIContainer.providerFactory.makeProvider()
//        )

//        let repository = Tab1Repository(
//            service: service,
//            tokenRepository: appDIContainer.tokenRepository
//        )

//        let useCase = Tab1UseCase(repository: repository)

        return MyPageViewModel(coordinator: coordinator)
    }

    func makeLabelsDIContainer() -> LabelsDIContainer {
        LabelsDIContainer(
            photoLabelDataRepository: appDIContainer.photoLabelDataRepository
        )
    }
    
    func makePhotoTestDIContainer() -> PhotoTestDIContainer {
        PhotoTestDIContainer(
            photoDataRepository: appDIContainer.photoDataRepository,
            geoRepository: appDIContainer.geoRepository
        )
    }
}
