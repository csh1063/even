//
//  LabelsCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

@MainActor
public class LabelsCoordinator: BaseCoordinator {
    
    private let diContainer: LabelsDIContainer
    private let navigationController: UINavigationController
    
    init(diContainer: LabelsDIContainer,
         navigationController: UINavigationController) {
        self.diContainer = diContainer
        self.navigationController = navigationController
        
        super.init()
    }

    public override func start() {
        print("start!")
        let viewModel = diContainer.makeLabelsViewModel { [weak self] in
            self?.pop()
        }
        let vc = LabelsViewController(viewModel: viewModel)

        navigationController.pushViewController(vc, animated: true)
        self.viewController = vc
    }
    
    private func pop() {
        navigationController.popViewController(animated: true)
        self.remove(coordinator: self)
    }
}
