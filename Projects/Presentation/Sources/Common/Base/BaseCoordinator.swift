//
//  BaseCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

@MainActor
open class BaseCoordinator: NSObject {
    
    public var viewController: UIViewController?
    public var hideTabBar: (() -> Void)?
    public var showTabBar: (() -> Void)?
    
    private var childCoordinators: [BaseCoordinator] = []
    
    public override init() {}
    
    open func start() { }
    
    public func start(coordinator: BaseCoordinator) {
        print("==== \(coordinator.self) start        ====================")
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func remove(coordinator: BaseCoordinator) {
        print("==== \(coordinator.self) start        ====================")
        childCoordinators.removeAll { $0 === coordinator }
    }
}

extension BaseCoordinator: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        
        guard let fromViewController = navigationController.transitionCoordinator?
            .viewController(forKey: .from) else { return }
        
        if navigationController.viewControllers.contains(fromViewController) { return }
        
        if navigationController.viewControllers.count == 1 {
            showTabBar?()
        }
        
        childCoordinators.forEach { coordinator in
            if coordinator.viewController === fromViewController {
                remove(coordinator: coordinator)
            }
        }
    }
}
