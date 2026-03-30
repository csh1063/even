//
//  AppCoordinator.swift
//  App
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Presentation
import Combine
import UIKit

@MainActor
final class AppCoordinator: BaseCoordinator {
    
    private let container: AppDIContainer
    private let window: UIWindow
    
    private var cancellables = Set<AnyCancellable>()

    init(container: AppDIContainer, window: UIWindow) {
        self.container = container
        self.window = window
        
        super.init()
    }

    override func start() {
        showSplash()
    }

    private func showSplash() {
        let splashCoordinator = SplashCoordinator(container: container, window: window)
        splashCoordinator.finished
            .sink { [weak self] isLogined in
                print("splashCoordinator finished")
                self?.showMain()
            }
            .store(in: &cancellables)
        start(coordinator: splashCoordinator)
    }
    
    private func showMain() {
        print("showMain!!")
        let mainDIContainer = MainDIContainer(appDiContainer: container)
        let mainCoordinator = MainCoordinator(container: mainDIContainer, window: window)
        mainCoordinator.logout
            .sink { [weak self] _ in
                self?.showSplash()
            }
            .store(in: &cancellables)
        start(coordinator: mainCoordinator)
    }
}
