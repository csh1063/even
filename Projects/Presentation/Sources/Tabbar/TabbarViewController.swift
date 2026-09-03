//
//  TabbarViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

final class TabbarViewController: CustomTabBarController {

    private let viewModel: TabbarViewModel

    private var showOnConsent: Bool = false
    private var showOnboarding: Bool = false

    /// 탭 전환도 "사용자가 화면을 이동했다" 신호 중 하나 — 분석 진행 미니위젯을 배지로 축소하는 데 쓴다.
    var onTabSelected: (() -> Void)?

    private var cancellables = Set<AnyCancellable>()

    init(viewModel: TabbarViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("TabbarViewController does not support NSCoding.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.binding()

        self.setBackgroundColor(Theme.background.withAlphaComponent(0.72))

        self.setItemColors(
            normal: Theme.textSecondary,
            selected: .white)
//            selected: Theme.primary)

//        self.setLayoutMargin(height: 68,
//                             margin: .init(leading: 0, trailing: 0, bottom: 0),
//                             padding: .init(leading: 12, trailing: 12))
        self.setAlign(.center)
        // leading은 평소(.center)엔 안 쓰이지만, 분석 진행 배지가 뜰 때 .left로 전환하는 순간 쓰인다
        // (setBadgeModeActive 참고) — 화면 맨 왼쪽에 딱 붙지 않도록 미리 여백을 정해둔다.
        self.setLayoutMargin(height: 56, itemWidth: 80,
                             margin: .init(leading: 20, bottom: 4),
                             padding: .zero, cornerRadius: 28)

        self.setShadow(color: .black, alpha: 0.3, x: 0, y: 4, blur: 16)

        self.setSelectedBox(color: Theme.primary)

        self.selectedIndex = 1

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        if !showOnboarding {
//            showOnboarding = true
//            let vc = OnboardingViewController()
//            vc.modalPresentationStyle = .fullScreen
//            self.present(vc, animated: true)
//        } else if !showOnConsent {
//            showOnConsent = true
//            let vc = ConsentViewController()
//            vc.modalPresentationStyle = .fullScreen
//            self.present(vc, animated: true)
//            
//        }

        viewModel.send(.showOnboarding)
    }

    private func binding() {

        let output = viewModel.transform()
        output.onboarding
            .sink { [weak self] isShow in
                if let isShow {
                    if !isShow {
                        let vc = OnboardingViewController()
                        vc.modalPresentationStyle = .fullScreen
                        vc.onClose = { [weak self] in
                            self?.viewModel.send(.afterOnboarding)
                        }
                        self?.present(vc, animated: true)
                    } else {
                        self?.viewModel.send(.showConsent)
                    }
                }
            }
            .store(in: &cancellables)

        output.consent
            .sink { [weak self] isShow in
                if let isShow, !isShow {
                    let vc = TermsViewController()
                    vc.modalPresentationStyle = .fullScreen
                    vc.onConsented = { [weak self] in
                        self?.viewModel.send(.afterConsent)
                    }
                    self?.present(vc, animated: true)
                }
            }
            .store(in: &cancellables)
    }

    func showTabbar() {
        self.animateFade(isShow: true)
    }

    func hideTabbar() {
        self.animateFade(isShow: false)
    }

    /// 분석 진행 배지(3단계)가 뜰 때만 탭바를 왼쪽으로 슬라이드해서 배지 자리를 내주고, 배지가
    /// 사라지면 다시 가운데로 되돌린다 — 평소(분석 안 할 때) 탭바 모양은 그대로 유지하기 위해 이
    /// 상태일 때만 정렬을 바꾼다.
    func setBadgeModeActive(_ isActive: Bool) {
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut]) {
            self.setAlign(isActive ? .left : .center)
            self.view.layoutIfNeeded()
        }
    }
}

extension TabbarViewController: CustomTabBarDelegate {
    func tabBarController(_ tabBarController: CustomTabBarController, didSelect viewController: UIViewController) {
        onTabSelected?()
    }
}
