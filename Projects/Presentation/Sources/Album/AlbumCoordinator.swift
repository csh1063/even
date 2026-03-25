//
//  AlbumCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

@MainActor
final class AlbumCoordinator: BaseCoordinator {
    
    private let diContainer: AlbumDIContainer
    private let navigationController = UINavigationController()
    
    init(diContainer: AlbumDIContainer) {
        self.diContainer = diContainer
    }

    override func start() {
        let viewModel = diContainer.makeAlbumViewModel()
        let vc = AlbumViewController(viewModel: viewModel)

        navigationController.viewControllers = [vc]
    }

    func startAndReturn() -> UINavigationController {
        start()
        return navigationController
    }
}
