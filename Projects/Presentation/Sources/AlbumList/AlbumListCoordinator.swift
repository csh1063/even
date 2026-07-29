//
//  AlbumListCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 6/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

@MainActor
public final class AlbumListCoordinator: BaseCoordinator {

    private let diContainer: AlbumListDIContainer
    private let navigationController: UINavigationController

    weak var delegate: AlbumDetailViewModelDelegate?

    /// 길게 눌러서 뜨는 앨범 메뉴("..." 메뉴와 동일) 동안 그 메뉴를 만든 AlbumDetailCoordinator를
    /// 붙잡아둔다 — 상세 화면으로 진입하지 않아서 childCoordinators에 들어가지 않으므로 여기서 직접 보관.
    private var albumMenuCoordinator: AlbumDetailCoordinator?

    init(diContainer: AlbumListDIContainer,
         navigationController: UINavigationController) {
        self.diContainer = diContainer
        self.navigationController = navigationController

        super.init()
    }

    public override func start() {
        let viewModel = diContainer.makeAlbumListViewModel()
//        self.delegate = viewModel
        viewModel.onAction = { [weak self] type in
            switch type {
            case .moveDetail(let album):
                self?.moveDetail(album: album, isSelectMode: album.from == "similar")
            case .pop:
                self?.pop()
            case .showAlbumMenu(let album):
                self?.showAlbumMenu(album: album)
            default: break
            }
        }

        bindAlert(from: viewModel)

        let vc = AlbumListViewController(viewModel: viewModel)

        navigationController.pushViewController(vc, animated: true)
        self.viewController = vc
    }

    private func pop() {
        navigationController.popViewController(animated: true)
        self.remove(coordinator: self)
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
