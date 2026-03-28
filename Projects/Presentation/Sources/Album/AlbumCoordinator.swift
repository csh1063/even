//
//  AlbumCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

@MainActor
public final class AlbumCoordinator: BaseCoordinator {
    
    private let diContainer: AlbumDIContainer
    private let navigationController = UINavigationController()
    
    init(diContainer: AlbumDIContainer) {
        self.diContainer = diContainer
    }

    public override func start() {
        let viewModel = diContainer.makeAlbumViewModel(coordinator: self)
        let vc = AlbumViewController(viewModel: viewModel)

        navigationController.delegate = self
        navigationController.viewControllers = [vc]
        self.viewController = vc
    }

    func startAndReturn() -> UINavigationController {
        start(coordinator: self)
        return navigationController
    }
    
    func moveDetail(folder: Folder) {
        print("move!")
        let detailDI = diContainer.makeDetailDIContainer(folder: folder)
        
        let detailCoordinator = AlbumDetailCoordinator(
            diContainer: detailDI,
            navigationController: self.navigationController
        )
        self.hideTabBar?()
        self.start(coordinator: detailCoordinator)
    }
}

//extension AlbumCoordinator: UINavigationControllerDelegate {
//    
//    public func navigationController(_ navigationController: UINavigationController,
//                            didShow viewController: UIViewController,
//                            animated: Bool) {
//        
//        // 이동 전 화면(FromVC)을 가져옴
//        guard let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from) else { return }
//        
//        // 만약 푸시된 화면들 중에 이 화면이 없다면 -> 사용자가 뒤로가기를 눌러서 팝된 것임
//        if navigationController.viewControllers.contains(fromViewController) { return }
//        
//        // 여기서 관련된 자식 코디네이터를 찾아 삭제
//        if fromViewController is AlbumDetailViewController {
//            // 자식들 중에 AlbumDetailCoordinator인 녀석을 찾아서 지움
//            childCoordinators.forEach { coordinator in
//                if let detailCoordinator = coordinator as? AlbumDetailCoordinator {
//                    self.remove(coordinator: detailCoordinator)
//                }
//            }
//        }
//    }
//}
