//
//  HomeCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

@MainActor
final class HomeCoordinator: BaseCoordinator {
    
    private let diContainer: HomeDIContainer
    private let navigationController = UINavigationController()
    
    init(diContainer: HomeDIContainer) {
        self.diContainer = diContainer
    }

    override func start() {
        let viewModel = diContainer.makeHomeViewModel()
        let vc = HomeViewController(viewModel: viewModel)

//        vc.onSelectItem = { [weak self] id in
//            self?.showDetail(id: id)
//        }

        navigationController.viewControllers = [vc]
    }

    func startAndReturn() -> UINavigationController {
        start()
//        navigationController.tabBarItem =
//            UITabBarItem(title: "Tab1", image: nil, selectedImage: nil)
        return navigationController
    }

//    private func showDetail(id: String) {
//        let detailDI = diContainer.makeDetailDIContainer(itemID: id)
//        let coordinator = Tab1DetailCoordinator(
//            navigationController: navigationController,
//            diContainer: detailDI
//        )
//        coordinator.start()
//    }
}
