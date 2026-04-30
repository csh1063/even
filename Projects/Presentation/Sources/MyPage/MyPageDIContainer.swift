//
//  MyPageDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 1/5/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class MyPageDIContainer {

    let appDIContainer: AppDIContainer

    public init(appDIContainer: AppDIContainer) {
        self.appDIContainer = appDIContainer
    }

    func makeMyPageViewModel(tabbarViewModel: TabbarViewModel) -> MyPageViewModel {

        let useCase = DefaultMyPageUseCase(
            photoLibraryRepository: appDIContainer.photoLibraryRepository,
            photoDataRepository: appDIContainer.photoDataRepository,
            userDefaultRepository: appDIContainer.userDefaultRepository
        )

        return MyPageViewModel(tabbarViewModel: tabbarViewModel, myPageUseCase: useCase)
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
