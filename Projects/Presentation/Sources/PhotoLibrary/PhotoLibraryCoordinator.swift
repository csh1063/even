//
//  PhotoLibraryCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Domain

@MainActor
final class PhotoLibraryCoordinator: BaseCoordinator {
    
    private let diContainer: PhotoLibraryDIContainer
    private let tabbarViewModel: TabbarViewModel
    
    private let navigationController = UINavigationController()
    
    init(diContainer: PhotoLibraryDIContainer, tabbarViewModel: TabbarViewModel) {
        self.diContainer = diContainer
        self.tabbarViewModel = tabbarViewModel
        
        super.init()
    }

    override func start() {
        let viewModel = diContainer.makePhotoLibraryViewModel(tabbarViewModel: tabbarViewModel)
        viewModel.onAction = { [weak self] action in
            print("onAction")
            switch action {
            case .selectPhoto(let photoDetails, let index):
                print("move", index)
                self?.showDetail(photoDetails, index: index)
            }
        }
        let vc = PhotoLibraryViewController(viewModel: viewModel)

        navigationController.viewControllers = [vc]
        self.viewController = vc
    }

    func startAndReturn() -> UINavigationController {
        start(coordinator: self)
//        navigationController.tabBarItem =
//            UITabBarItem(title: "Tab1", image: nil, selectedImage: nil)
        return navigationController
    }

    func showDetail(_ photoDetails: [PhotoDetail], index: Int) {
        print("showDetail")
        let vm = diContainer.makeImageViewerViewModel(photoDetails: photoDetails, index: index)
        vm.onAction = { [weak self] action in
            switch action {
            case .pageChanged(let id):
                (self?.viewController as? PhotoLibraryViewController)?.scrollToItem(id: id)
            case .selectionChanged: break
            }
        }
        let vc = ImageViewerViewController(viewModel: vm)
        
        navigationController.present(vc, animated: true)
    }
}
