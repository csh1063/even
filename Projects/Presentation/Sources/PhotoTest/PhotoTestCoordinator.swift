//
//  PhotoTestCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 4/8/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

@MainActor
public final class PhotoTestCoordinator: BaseCoordinator {
    
    private let diContainer: PhotoTestDIContainer
    private let navigationController: UINavigationController
    
    init(diContainer: PhotoTestDIContainer,
         navigationController: UINavigationController) {
        self.diContainer = diContainer
        self.navigationController = navigationController
        
        super.init()
    }

    public override func start() {
        print("start!")
        let viewModel = diContainer.makePhotoTestViewModel { [weak self] in
            self?.pop()
        }
        
        bindAlert(from: viewModel)
        
        let vc = PhotoTestViewController(viewModel: viewModel)

        navigationController.pushViewController(vc, animated: true)
        self.viewController = vc
    }
    
    private func pop() {
        navigationController.popViewController(animated: true)
        self.remove(coordinator: self)
    }
}
