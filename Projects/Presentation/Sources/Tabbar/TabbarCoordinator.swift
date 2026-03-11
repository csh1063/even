//
//  TabbarCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

@MainActor
final class TabbarCoordinator: BaseCoordinator {
    
    private let container: TabbarDIContainer
    private let window: UIWindow
    private var tabbarViewController: TabbarViewController?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(container: TabbarDIContainer, window: UIWindow) {
        self.container = container
        self.window = window
    }

    public override func start() {
        
        self.tabbarViewController = TabbarViewController()
        
        let home = container.makeHomeCoordinator().startAndReturn()
        let list = container.makeListCoordinator().startAndReturn()
        let myPage = container.makeMyPageCoordinator().startAndReturn()
        
        self.tabbarViewController?.setTabBarItem("house", selectedImage: "house.fill", vc: home, title: "홈")
        self.tabbarViewController?.setTabBarItem("list.bullet.rectangle.portrait", selectedImage: "list.bullet.rectangle.portrait.fill", vc: list)//, title: "리스트")
        self.tabbarViewController?.setTabBarItem("person", selectedImage: "person.fill", vc: myPage)//, title: "마이")
        
        let controllers = [home,
                           list,
                           myPage]
        
        self.tabbarViewController?.setViewControllers(controllers)
        self.tabbarViewController?.setItemColors(normal: .gray, selected: .black)
        
        window.rootViewController = self.tabbarViewController
        window.makeKeyAndVisible()
    }
}
