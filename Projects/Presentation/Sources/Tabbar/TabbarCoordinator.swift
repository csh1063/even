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
        // 같은 progress를 보여주는 플로팅 미니 진행률이 이미 떠 있다면(최소화 상태에서 다시 시트를
        // 열게 되는 경우) 중복 표시되지 않도록 먼저 치운다.
        AnalysisProgressManager.shared.hide()

        let sheet = AlbumAnalysisSheet(progress: progress)
        sheet.isModalInPresentation = true
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium()]
            presentation.preferredCornerRadius = 28
        }
        // 사용자가 명시적으로 최소화 버튼을 눌러 시트를 닫으면(스와이프/탭-아웃은 여전히 막혀있음),
        // 진행 중이던 분석/앨범생성 진행률을 그대로 물려받는 플로팅 미니 진행률로 대체한다 — 분석
        // 자체는 계속 진행된다. 플로팅 미니 진행률을 다시 탭하면 원래 시트로 복귀한다.
        sheet.onMinimize = { [weak self] in
            AnalysisProgressManager.shared.show(
                locationProgress: progress.photoProgress,
                albumProgress: progress.albumProgress,
                onTap: {
                    // 슬라이드-아웃 애니메이션이 실제로 끝난 뒤에 시트를 띄운다 — 바로 present하면
                    // 위젯이 사라지는 게 아니라 새로 뜬 시트에 그냥 가려져서 애니메이션이 안 보였다.
                    AnalysisProgressManager.shared.hide(delay: 0) {
                        self?.showAnalysisSheet(progress: progress)
                    }
                }
            )
        }

        tabbarViewController?.present(sheet, animated: true)
    }
}
