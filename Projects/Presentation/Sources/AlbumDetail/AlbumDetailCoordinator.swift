//
//  AlbumDetailCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 3/28/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

@MainActor
public final class AlbumDetailCoordinator: BaseCoordinator {
    
    private let diContainer: AlbumDetailDIContainer
    private let navigationController: UINavigationController
    
    init(diContainer: AlbumDetailDIContainer,
         navigationController: UINavigationController) {
        self.diContainer = diContainer
        self.navigationController = navigationController
    }

    public override func start() {
        print("start!")
        let viewModel = diContainer.makeAlbumViewModel { [weak self] in
            self?.pop()
        }
        let vc = AlbumDetailViewController(viewModel: viewModel)

        navigationController.pushViewController(vc, animated: true)
        self.viewController = vc
    }
    
    private func pop() {
        navigationController.popViewController(animated: true)
        self.remove(coordinator: self)
    }
}
