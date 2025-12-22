//
//  MainCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

public final class MainCoordinator: BaseCoordinator {
    private let container: AppDIContainer
    private let window: UIWindow
    public var finished = PassthroughSubject<Bool, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(container: AppDIContainer, window: UIWindow) {
        self.container = container
        self.window = window
    }

    public override func start() {
        let viewModel = container.makeMainViewModel()
        let viewController = MainViewController(viewModel: viewModel)

        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }
}
