//
//  MainDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

@MainActor
public final class MainDIContainer {
    
    private let appDiContainer: AppDIContainer
    
    public init(appDiContainer: AppDIContainer) {
        self.appDiContainer = appDiContainer
    }
    
    func makeTabBarDIContainer() -> TabbarDIContainer {
        TabbarDIContainer(appDiContainer: appDiContainer)
    }
}
