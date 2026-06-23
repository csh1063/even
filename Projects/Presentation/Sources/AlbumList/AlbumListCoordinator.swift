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
    
    init(diContainer: AlbumListDIContainer,
         navigationController: UINavigationController) {
        self.diContainer = diContainer
        self.navigationController = navigationController
        
        super.init()
    }

    public override func start() {
        print("start!")
        let viewModel = diContainer.makeAlbumListViewModel()
//        self.delegate = viewModel
        viewModel.onAction = { [weak self] type in
            switch type {
            case .moveDetail(let album):
                self?.moveDetail(album: album)
            case .pop:
                self?.pop()
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
    
    func moveDetail(album: Album) {
        print("move!")
        let detailDI = diContainer.makeDetailDIContainer(album: album)
        
        let detailCoordinator = AlbumDetailCoordinator(
            diContainer: detailDI,
            navigationController: self.navigationController
        )
        self.hideTabBar?()
        self.start(coordinator: detailCoordinator)
    }
}
