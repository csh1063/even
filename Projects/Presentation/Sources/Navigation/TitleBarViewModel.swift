//
//  TitleBarViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 3/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit
import Combine

// MARK: - TitleBarViewModel

final class TitleBarViewModel {

    // MARK: - Properties

    private(set) weak var view: TitleBarView?

    var leftType: TitleLeftType { view?.leftType ?? .clear }
    var rightType: TitleRightType { view?.rightType ?? .clear }

    // MARK: - Init

    init(view: TitleBarView) {
        self.view = view
    }

    // MARK: - Scroll Interaction

    /// 스크롤 비율(0~1)에 따라 타이틀 라벨 Y 위치를 애니메이션
    func animateTitleBar(ratio: CGFloat) {
        view?.titleLabel.frame.origin.y = 7 * ratio - 7
    }

    // MARK: - Appearance

    /// 투명 배경 모드 (예: 이미지 위에 오버레이되는 상태)
    func setTransparent() {
        guard let view else { return }
        view.clipsToBounds = true
        view.backgroundColor = .clear
        updateBlurViewTopOffset(416)
//        view.outerLeftButton.editNaviButtonForm(
//            color: UIColor.Theme.white,
//            image: UIImage.SsoldotAssets.iconBack
//        )
    }

    /// 기본 불투명 배경 모드
    func setOpaque() {
        guard let view else { return }
        view.clipsToBounds = false
        view.backgroundColor = UIColor.Theme.white.withAlphaComponent(0.7)
        updateBlurViewTopOffset(0)
//        view.outerLeftButton.editNaviButtonForm(
//            color: UIColor.Theme.primary,
//            image: UIImage.SsoldotAssets.iconBackSelected
//        )
    }

    // MARK: - Private

    private func updateBlurViewTopOffset(_ offset: CGFloat) {
        view?.blurView.snp.updateConstraints { make in
            make.top.equalTo(view!).offset(offset)
        }
    }
}
