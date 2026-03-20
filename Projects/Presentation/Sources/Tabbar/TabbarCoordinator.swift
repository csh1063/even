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
        
        let photo = container.makePhotoLibraryCoordinator().startAndReturn()
        let album = container.makeAlbumCoordinator().startAndReturn()
        let myPage = container.makeMyPageCoordinator().startAndReturn()
        
        self.tabbarViewController?.setTabBarItem("house", selectedImage: "house.fill", vc: photo)//, title: "홈")
        self.tabbarViewController?.setTabBarItem("list.bullet.rectangle.portrait", selectedImage: "list.bullet.rectangle.portrait.fill", vc: album)//, title: "리스트")
        self.tabbarViewController?.setTabBarItem("person", selectedImage: "person.fill", vc: myPage)//, title: "마이")
        
        let controllers = [photo,
                           album,
                           myPage]
        
        self.tabbarViewController?.setViewControllers(controllers)
        
        window.rootViewController = self.tabbarViewController
        window.makeKeyAndVisible()
    }
}
