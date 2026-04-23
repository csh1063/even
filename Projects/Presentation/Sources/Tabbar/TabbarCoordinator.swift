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
        
        super.init()
    }

    public override func start() {
        
        self.tabbarViewController = TabbarViewController()
        
        let photoCoordinator = container.makePhotoLibraryCoordinator()
        let albumCoordinator = container.makeAlbumCoordinator()
        let myPageCoordinator = container.makeMyPageCoordinator()
        [photoCoordinator, albumCoordinator, myPageCoordinator].forEach {
            $0.hideTabBar = { [weak self] in
                self?.tabbarViewController?.hideTabbar()
            }
            
            $0.showTabBar = { [weak self] in
                self?.tabbarViewController?.showTabbar()
            }
        }
        let photo = photoCoordinator.startAndReturn()
        let album = albumCoordinator.startAndReturn()
        let myPage = myPageCoordinator.startAndReturn()
        
        self.tabbarViewController?.setTabBarItem("photo.on.rectangle.angled", vc: photo)//, title: "홈")
        self.tabbarViewController?.setTabBarItem("square.stack.fill", vc: album)//, title: "리스트")
        self.tabbarViewController?.setTabBarItem("person.fill", vc: myPage)//, title: "마이")
        
        let controllers = [photo,
                           album,
                           myPage]
        
        self.tabbarViewController?.setViewControllers(controllers)
        
        window.rootViewController = self.tabbarViewController
        window.makeKeyAndVisible()
    }
}
