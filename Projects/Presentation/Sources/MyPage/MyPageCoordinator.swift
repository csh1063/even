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
    private let tabbarViewModel: TabbarViewModel
    private let navigationController = UINavigationController()
    
    init(diContainer: MyPageDIContainer, tabbarViewModel: TabbarViewModel) {
        self.diContainer = diContainer
        self.tabbarViewModel = tabbarViewModel
        
        super.init()
    }

    public override func start() {
        let viewModel = diContainer.makeMyPageViewModel(tabbarViewModel: tabbarViewModel)
        viewModel.onAction = { [weak self] action in
            switch action {
            case .move(let data):
                switch data.type {
                case .labels:
                    self?.moveLabels()
                case .test:
                    self?.moveTest()
                default: break
                }
            }
        }
        
        let vc = MyPageViewController(viewModel: viewModel)

        bindAlert(from: viewModel)
        
        navigationController.delegate = self
        navigationController.viewControllers = [vc]
        self.viewController = vc
    }

    func startAndReturn() -> UINavigationController {
        start(coordinator: self)
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
    
    func moveTest() {
        print("test!")
        let detailDI = diContainer.makePhotoTestDIContainer()
        
        let detailCoordinator = PhotoTestCoordinator(
            diContainer: detailDI,
            navigationController: self.navigationController
        )
        self.hideTabBar?()
        self.start(coordinator: detailCoordinator)
    }
}
