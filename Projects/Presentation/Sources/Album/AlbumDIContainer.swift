//
//  AlbumDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 1/5/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//`

import Foundation

@MainActor
final class AlbumDIContainer {

    let appDIContainer: AppDIContainer

    init(appDIContainer: AppDIContainer) {
        self.appDIContainer = appDIContainer
    }

    func makeAlbumViewModel() -> AlbumViewModel {
//        let service = Tab1Service(
//            provider: appDIContainer.providerFactory.makeProvider()
//        )

//        let repository = Tab1Repository(
//            service: service,
//            tokenRepository: appDIContainer.tokenRepository
//        )

//        let useCase = Tab1UseCase(repository: repository)

        return appDIContainer.makeAlbumViewModel()
    }

//    func makeDetailDIContainer(
//        itemID: String
//    ) -> Tab1DetailDIContainer {
//        Tab1DetailDIContainer(
//            appDIContainer: appDIContainer,
//            itemID: itemID
//        )
//    }
}
