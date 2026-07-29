//
//  AlbumCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

@MainActor
public final class AlbumCoordinator: BaseCoordinator {

    private let diContainer: AlbumDIContainer
    private let tabbarViewModel: TabbarViewModel

    private let navigationController = UINavigationController()

    /// 길게 눌러서 뜨는 앨범 메뉴("..." 메뉴와 동일) 동안 그 메뉴를 만든 AlbumDetailCoordinator를
    /// 붙잡아둔다 — 상세 화면으로 진입하지 않아서 childCoordinators에 들어가지 않으므로 여기서 직접 보관.
    private var albumMenuCoordinator: AlbumDetailCoordinator?

    init(diContainer: AlbumDIContainer, tabbarViewModel: TabbarViewModel) {
        self.diContainer = diContainer
        self.tabbarViewModel = tabbarViewModel

        super.init()
    }

    public override func start() {
        let viewModel = diContainer.makeAlbumViewModel(tabbarViewModel: tabbarViewModel)
        viewModel.onAction = { [weak self] type in
            switch type {
            case .moveDetail(let album):
                self?.moveDetail(album: album, isSelectMode: album.from == "similar")
            case .more(let from):
                self?.moveFromList(from)
            case .showAlbumMenu(let album):
                self?.showAlbumMenu(album: album)
            default: break
            }
        }

        let vc = AlbumViewController(viewModel: viewModel)

        bindAlert(from: viewModel)

        navigationController.delegate = self
        navigationController.viewControllers = [vc]
        self.viewController = vc
    }

    func startAndReturn() -> UINavigationController {
        start(coordinator: self)
        return navigationController
    }

    func moveDetail(album: Album, isSelectMode: Bool) {
        let detailDI = diContainer.makeDetailDIContainer(album: album, isSelectMode: isSelectMode)

        let detailCoordinator = AlbumDetailCoordinator(
            diContainer: detailDI,
            navigationController: self.navigationController
        )
        self.hideTabBar?()
        self.start(coordinator: detailCoordinator)
    }

    func moveFromList(_ from: String) {
        let listDI = diContainer.makeListDIContainer(from: from)

        let listCoordinator = AlbumListCoordinator(
            diContainer: listDI,
            navigationController: self.navigationController
        )
        self.hideTabBar?()
        self.start(coordinator: listCoordinator)
    }

    /// 앨범을 길게 눌렀을 때 — 앨범 상세의 "..." 버튼과 완전히 동일한 메뉴를 상세 화면 진입 없이 띄운다.
    func showAlbumMenu(album: Album) {
        let detailDI = diContainer.makeDetailDIContainer(album: album, isSelectMode: false)
        let detailCoordinator = AlbumDetailCoordinator(
            diContainer: detailDI,
            navigationController: self.navigationController
        )
        self.albumMenuCoordinator = detailCoordinator
        detailCoordinator.presentAlbumMenu(album: album)
    }
}

// extension AlbumCoordinator: UINavigationControllerDelegate {
//    
//    public func navigationController(_ navigationController: UINavigationController,
//                            didShow viewController: UIViewController,
//                            animated: Bool) {
//        
//        // 이동 전 화면(FromVC)을 가져옴
//        guard let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from) else { return }
//        
//        // 만약 푸시된 화면들 중에 이 화면이 없다면 -> 사용자가 뒤로가기를 눌러서 팝된 것임
//        if navigationController.viewControllers.contains(fromViewController) { return }
//        
//        // 여기서 관련된 자식 코디네이터를 찾아 삭제
//        if fromViewController is AlbumDetailViewController {
//            // 자식들 중에 AlbumDetailCoordinator인 녀석을 찾아서 지움
//            childCoordinators.forEach { coordinator in
//                if let detailCoordinator = coordinator as? AlbumDetailCoordinator {
//                    self.remove(coordinator: detailCoordinator)
//                }
//            }
//        }
//    }
// }
