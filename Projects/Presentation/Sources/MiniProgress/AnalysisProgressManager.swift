//
//  AnalysisProgressManager.swift
//  Presentation
//
//  Created by sanghyeon on 4/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Combine

final class AnalysisProgressManager {
    static let shared = AnalysisProgressManager()

    var isPresenting: Bool = false

    private var window: UIWindow?
    private var floatingView: MiniProgressView?
    private var isHiding: Bool = false

    func show(
        locationProgress: AnyPublisher<Double, Never>,
        albumProgress: AnyPublisher<Double, Never>,
        onTap: (() -> Void)? = nil
    ) {
        guard !isPresenting else {return}

        isPresenting = true

        let view = MiniProgressView()
        view.bind(locationProgress: locationProgress, albumProgress: albumProgress)
        view.onTap = onTap

        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        window.addSubview(view)

        view.snp.makeConstraints { make in
            make.trailing.equalTo(184)
            make.bottom.equalTo(window).offset(-120)
            make.width.equalTo(176)
            make.height.equalTo(72)
        }
        window.layoutIfNeeded()

        self.window = window
        self.floatingView = view

        view.snp.updateConstraints { make in
            make.trailing.equalTo(-20)
        }

        UIView.animate(withDuration: 0.5) {
            window.layoutIfNeeded()
        }
    }

    /// - delay: 애니메이션 시작 전 대기 시간. 완료 상태(progress 1.0)에서 자동으로 사라질 땐 잠깐
    ///   보여준 뒤 사라지는 게 자연스러워서 기본값 0.5초를 쓰고, 사용자가 위젯을 직접 탭해서 원래
    ///   화면으로 복귀할 땐(TabbarCoordinator) 0을 넘겨서 바로 슬라이드-아웃되게 한다.
    /// - completion: 슬라이드-아웃 애니메이션이 실제로 끝난 뒤 호출된다 — 탭 복귀 플로우에서 이
    ///   애니메이션이 끝나기 전에 시트를 바로 present해버리면 위젯이 화면에서 사라지는 게 아니라
    ///   새로 뜨는 시트에 그냥 가려져서 "슬라이드 안 하고 뚝 끊기는" 것처럼 보이는 문제가 있었다.
    func hide(delay: TimeInterval = 0.5, completion: (() -> Void)? = nil) {

        guard !isHiding else { completion?(); return }
        isHiding = true

        guard let window else {
            floatingView?.removeFromSuperview()
            floatingView = nil
            isPresenting = false
            isHiding = false
            completion?()
            return
        }

        self.floatingView?.snp.updateConstraints { make in
            make.trailing.equalTo(184)
        }

        UIView.animate(withDuration: 0.5, delay: delay) {
            window.layoutIfNeeded()
        } completion: { success in
            if success {
                self.floatingView?.removeFromSuperview()
                self.floatingView = nil
                self.isPresenting = false
                self.isHiding = false
            }
            completion?()
        }
    }
}
