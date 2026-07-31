//
//  TabbarCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

@MainActor
final class TabbarCoordinator: BaseCoordinator {

    private let container: TabbarDIContainer
    private var tabbarViewController: TabbarViewController?
    private let window: UIWindow

    private var cancellables = Set<AnyCancellable>()

    public init(container: TabbarDIContainer, window: UIWindow) {
        self.container = container
        self.window = window

        super.init()
    }

    public override func start() {

        let viewModel = container.makeTabbarViewModel()
        viewModel.onAction = { [weak self] type in
            switch type {
            case .progressSheet(let progress):
                self?.showAnalysisSheet(progress: progress)
            }
        }

        bindAlert(from: viewModel)

        self.tabbarViewController = TabbarViewController(viewModel: viewModel)

        let photoCoordinator = makePhotoLibraryCoordinator(viewModel: viewModel)
        let albumCoordinator = makeAlbumCoordinator(viewModel: viewModel)
        let myPageCoordinator = makeMyPageCoordinator(viewModel: viewModel)
        [photoCoordinator, albumCoordinator, myPageCoordinator].forEach {
            $0.hideTabBar = { [weak self] in
                self?.tabbarViewController?.hideTabbar()
            }

            $0.showTabBar = { [weak self] in
                self?.tabbarViewController?.showTabbar()
            }
        }
        let photo = photoCoordinator.startAndReturn()
        let album = albumCoordinator.startAndReturn()
        let myPage = myPageCoordinator.startAndReturn()

        self.tabbarViewController?.setTabBarItem("photo.on.rectangle.angled", vc: photo, title: String(localized: "사진첩", bundle: .module))
        self.tabbarViewController?.setTabBarItem("square.stack", vc: album, title: String(localized: "앨범", bundle: .module))
        self.tabbarViewController?.setTabBarItem("gearshape", vc: myPage, title: String(localized: "설정", bundle: .module))

        let controllers = [photo,
                           album,
                           myPage]

        self.tabbarViewController?.setViewControllers(controllers)

        window.rootViewController = self.tabbarViewController
        window.makeKeyAndVisible()
    }

    private func makePhotoLibraryCoordinator(viewModel: TabbarViewModel) -> PhotoLibraryCoordinator {
        let diContainer = container.makePhotoLibraryDIContainer()
        return PhotoLibraryCoordinator(diContainer: diContainer, tabbarViewModel: viewModel)
    }

    private func makeAlbumCoordinator(viewModel: TabbarViewModel) -> AlbumCoordinator {
        let diContainer = container.makeAlbumDIContainer()
        return AlbumCoordinator(diContainer: diContainer, tabbarViewModel: viewModel)
    }

    private func makeMyPageCoordinator(viewModel: TabbarViewModel) -> MyPageCoordinator {
        let diContainer = container.makeMyPageDIContainer()
        return MyPageCoordinator(diContainer: diContainer, tabbarViewModel: viewModel)
    }

    private func showAnalysisSheet(progress: AnalyzeProgress) {
        let sheet = AlbumAnalysisSheet(progress: progress)
        sheet.isModalInPresentation = true
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium()]
            presentation.preferredCornerRadius = 28
        }

        tabbarViewController?.present(sheet, animated: true)
    }
}
