//
//  SplashCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

@MainActor
public final class SplashCoordinator: BaseCoordinator {
    
    private let container: AppDIContainer
    private let window: UIWindow
    public var finished = PassthroughSubject<Bool, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(container: AppDIContainer, window: UIWindow) {
        self.container = container
        self.window = window
        
        super.init()
    }

    public override func start() {
        let viewModel = container.makeSplashViewModel()
        viewModel.output.finished
            .sink { [weak self] isLogined in
                print("SplashCoordinator finished")
                self?.finished.send(isLogined)
            }
            .store(in: &cancellables)
        
        bindAlert(from: viewModel)
        
        let viewController = SplashViewController(viewModel: viewModel)

        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }
}
