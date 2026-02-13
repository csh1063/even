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
    
    func makeHomeCoordinator() -> HomeCoordinator {
        let diContainer = HomeDIContainer(appDIContainer: appDiContainer)
        return HomeCoordinator(diContainer: diContainer)
    }
    
    func makeListCoordinator() -> ListCoordinator {
        let diContainer = ListDIContainer(appDIContainer: appDiContainer)
        return ListCoordinator(diContainer: diContainer)
    }
    
    func makeMyPageCoordinator() -> MyPageCoordinator {
        let diContainer = MyPageDIContainer(appDIContainer: appDiContainer)
        return MyPageCoordinator(diContainer: diContainer)
    }
}
