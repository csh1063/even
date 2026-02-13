//
//  HomeDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 1/5/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

@MainActor
final class HomeDIContainer {

    let appDIContainer: AppDIContainer

    init(appDIContainer: AppDIContainer) {
        self.appDIContainer = appDIContainer
    }

    func makeHomeViewModel() -> HomeViewModel {
//        let service = Tab1Service(
//            provider: appDIContainer.providerFactory.makeProvider()
//        )

//        let repository = Tab1Repository(
//            service: service,
//            tokenRepository: appDIContainer.tokenRepository
//        )

//        let useCase = Tab1UseCase(repository: repository)

        return HomeViewModel()
    }

//    func makeHomeDetailViewModel(
//        id: String
//    ) -> HomeDetailViewModel {
//    }
}
