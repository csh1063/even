//
//  TabbarDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

@MainActor
public final class TabbarDIContainer {
    
    private let appDiContainer: AppDIContainer
    
    public init(appDiContainer: AppDIContainer) {
        self.appDiContainer = appDiContainer
    }
    
    func makePhotoLibraryCoordinator() -> PhotoLibraryCoordinator {
        let diContainer = PhotoLibraryDIContainer(appDIContainer: appDiContainer)
        return PhotoLibraryCoordinator(diContainer: diContainer)
    }
    
    func makeAlbumCoordinator() -> AlbumCoordinator {
        let diContainer = AlbumDIContainer(appDIContainer: appDiContainer)
        return AlbumCoordinator(diContainer: diContainer)
    }
    
    func makeMyPageCoordinator() -> MyPageCoordinator {
        let diContainer = MyPageDIContainer(appDIContainer: appDiContainer)
        return MyPageCoordinator(diContainer: diContainer)
    }
}
