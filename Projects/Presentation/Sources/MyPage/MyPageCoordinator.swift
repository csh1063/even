//
//  MyPageCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

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
                    self?.moveLabels(isLabel: true)
                case .addressCount:
                    self?.moveLabels(isLabel: false)
                case .privacy:
                    let vc = WebDocuViewController(type: .privacy)
                    self?.navigationController.pushViewController(vc, animated: true)
                case .terms:
                    let vc = WebDocuViewController(type: .terms)
                    self?.navigationController.pushViewController(vc, animated: true)
//                    let urlString = data.type == .terms
//                        ? "https://csh1063.github.io/moa-web/terms-of-service.html"
//                        : "https://csh1063.github.io/moa-web/privacy-policy.html"
//                    guard let url = URL(string: urlString) else { return }
//
//                    let vc = SFSafariViewController(url: url)
//                    
//                    self?.navigationController.pushViewController(vc, animated: true)
                case .openSource:
                    let vc = OpenSourceViewController()
                    self?.navigationController.pushViewController(vc, animated: true)
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
    
    func moveLabels(isLabel: Bool) {
        print("move!")
        let detailDI = diContainer.makeLabelsDIContainer(isLabel: isLabel)
        
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
