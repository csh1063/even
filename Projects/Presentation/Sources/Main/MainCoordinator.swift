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

@MainActor
public final class MainCoordinator: BaseCoordinator {
    
    public var logout = PassthroughSubject<Bool, Never>()
    
    private let mainDIConatiner: MainDIContainer
    private let window: UIWindow
    private var rootVC: UIViewController?

    public init(container: MainDIContainer, window: UIWindow) {
        self.mainDIConatiner = container
        self.window = window
        
        super.init()
    }

    public override func start() {
        let tabbarContainer = mainDIConatiner.makeTabBarDIContainer()
        let tabbarCoordinator = TabbarCoordinator(container: tabbarContainer, window: window)
        start(coordinator: tabbarCoordinator)
    }
}
