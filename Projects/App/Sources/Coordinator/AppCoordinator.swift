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

final class AppCoordinator: BaseCoordinator {
    
    private let window: UIWindow
    private let container: AppDIContainer
    
    private var cancellables = Set<AnyCancellable>()

    init(container: AppDIContainer, window: UIWindow) {
        self.container = container
        self.window = window
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
//        let mainCoordinator = MainCoordinator(container: container, window: window)
//        mainCoordinator.logout
//            .sink { [weak self] in
//                self?.showSplash()
//            }
//            .store(in: &cancellables)
//        start(coordinator: mainCoordinator)
    }
}
