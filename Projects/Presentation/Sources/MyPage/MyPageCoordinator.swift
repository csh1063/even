//
//  MyPageCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

@MainActor
public final class MyPageCoordinator: BaseCoordinator {
    
    private let diContainer: MyPageDIContainer
    private let navigationController = UINavigationController()
    
    init(diContainer: MyPageDIContainer) {
        self.diContainer = diContainer
        
        super.init()
    }

    public override func start() {
        let viewModel = diContainer.makeMyPageViewModel(coordinator: self)
        let vc = MyPageViewController(viewModel: viewModel)

//        vc.onSelectItem = { [weak self] id in
//            self?.showDetail(id: id)
//        }
        
        bindAlert(from: viewModel)

        navigationController.viewControllers = [vc]
    }

    func startAndReturn() -> UINavigationController {
        start()
//        navigationController.tabBarItem =
//            UITabBarItem(title: "Tab1", image: nil, selectedImage: nil)
        return navigationController
    }
    
    func moveLabels() {
        print("move!")
        let detailDI = diContainer.makeLabelsDIContainer()
        
        let detailCoordinator = LabelsCoordinator(
            diContainer: detailDI,
            navigationController: self.navigationController
        )
        self.hideTabBar?()
        self.start(coordinator: detailCoordinator)
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
