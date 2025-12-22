//
//  BaseCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

open class BaseCoordinator {
    private var childCoordinators: [BaseCoordinator] = []
    
    public init() {}
    
    open func start() { }
    
    public func start(coordinator: BaseCoordinator) {
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func remove(coordinator: BaseCoordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
}
