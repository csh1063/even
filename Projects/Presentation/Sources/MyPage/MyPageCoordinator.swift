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
                    self?.hideTabBar?()
                    self?.navigationController.pushViewController(vc, animated: true)
                case .terms:
                    let vc = WebDocuViewController(type: .terms)
                    self?.hideTabBar?()
                    self?.navigationController.pushViewController(vc, animated: true)
                case .feedback:
                    self?.moveFeedback()
//                case .displayMode:
//                    let vc = OptionPickerViewController(
//                        title: "디스플레이 모드",
//                        options: DisplayMode.allCases.map {$0.text},
//                        selected: data.value
//                    )
//                    vc.onSelect = { [weak viewModel] selected in
//                        // 저장 버튼 눌렀을 때 여기서 selected 사용
//                        print("??")
//                        Task { @MainActor in
//                            print("?!")
//                            await viewModel?.changeDisplayMode(selected)
//                        }
//                    }
//                    self?.hideTabBar?()
//                    self?.navigationController.pushViewController(vc, animated: true)
                case .openSource:
                    let vc = OpenSourceViewController()
                    self?.hideTabBar?()
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

    func moveFeedback() {
        let viewModel = diContainer.makeFeedbackViewModel()
        bindAlert(from: viewModel)
        let vc = FeedbackViewController(viewModel: viewModel)
        self.hideTabBar?()
        self.navigationController.pushViewController(vc, animated: true)
    }

    func moveLabels(isLabel: Bool) {
        let detailDI = diContainer.makeLabelsDIContainer(isLabel: isLabel)

        let detailCoordinator = LabelsCoordinator(
            diContainer: detailDI,
            navigationController: self.navigationController
        )
        self.hideTabBar?()
        self.start(coordinator: detailCoordinator)
    }

    func moveTest() {
        let detailDI = diContainer.makePhotoTestDIContainer()

        let detailCoordinator = PhotoTestCoordinator(
            diContainer: detailDI,
            navigationController: self.navigationController
        )
        self.hideTabBar?()
        self.start(coordinator: detailCoordinator)
    }
}
