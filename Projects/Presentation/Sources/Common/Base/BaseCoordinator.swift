//
//  BaseCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

@MainActor
open class BaseCoordinator: NSObject {

    var viewController: UIViewController?
    var hideTabBar: (() -> Void)?
    var showTabBar: (() -> Void)?
    /// 이 코디네이터가 소유한 네비게이션 컨트롤러에서 push/pop으로 화면이 바뀔 때마다 불린다(자식
    /// 코디네이터가 같은 네비게이션 컨트롤러에 푸시해도 델리게이트는 이 인스턴스 하나라 전부 여기로
    /// 잡힌다). 분석 진행 미니위젯을 "화면을 이동하면 배지로 축소" 시키는 신호로 쓴다.
    var onNavigate: (() -> Void)?

    private var childCoordinators: [BaseCoordinator] = []

    private let alertManager: AlertManageable
    private var cancellables = Set<AnyCancellable>()

//    public override init() {}

    public init(alertManager: AlertManageable = AlertManager.shared) {
        self.alertManager = alertManager
    }

    open func start() { }

    public func start(coordinator: BaseCoordinator) {
        childCoordinators.append(coordinator)
        coordinator.start()
    }

    func remove(coordinator: BaseCoordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }

    func bindAlert(from viewModel: BaseViewModel) {
        viewModel.alertPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                self?.alertManager.enqueue(
                    title: item.title,
                    message: item.message,
                    buttons: item.buttons
                )
            }
            .store(in: &cancellables)
    }
}

extension BaseCoordinator: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        onNavigate?()

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
