//
//  SplashViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

final class SplashViewController: BaseViewController {

    // MARK: - Constants

    private let cardSize = CGSize(width: 120, height: 150)
    private let innerInset: CGFloat = 10
    private let innerHeight: CGFloat = 95

    // MARK: - Views

    private let cardsContainer = UIView()

    private lazy var cardLeft: UIView = makeCard()
    private lazy var cardRight: UIView = makeCard()
    private lazy var cardCenter: UIView = makeCard()

    private let cardLeftInner: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.primary
        view.layer.cornerRadius = 6
        return view
    }()

    private let cardRightInner: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.secondary
        view.layer.cornerRadius = 6
        return view
    }()

    private let cardCenterInner: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.accent
        view.layer.cornerRadius = 6
        return view
    }()

    private let moaCardLabel: UILabel = {
        let label = UILabel()
        label.text = "moa"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = Theme.textPrimary
        label.textAlignment = .center
        label.alpha = 0
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "moa"
        label.font = UIFont.systemFont(ofSize: 34, weight: .semibold)
        label.textColor = Theme.textPrimary
        label.alpha = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "당신의 순간을 모으다", bundle: .module)
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = Theme.textSecondary
        label.alpha = 0
        return label
    }()

    private let textStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }()

    private let viewModel: SplashViewModel

    override var pageTitle: String? { "스플래시" }

    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        setupHierarchy()
        setupConstraints()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.send(.appear)
        self.runAnimation { [weak self] in
            self?.viewModel.send(.endAnim)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCardFrames()
    }

    private func setupHierarchy() {
        view.addSubview(cardsContainer)

        // z-order: left → right → center
        for (card, inner) in [(cardLeft, cardLeftInner),
                              (cardRight, cardRightInner),
                              (cardCenter, cardCenterInner)] {
            cardsContainer.addSubview(card)
            card.addSubview(inner)
            card.alpha = 0
        }

        cardCenter.addSubview(moaCardLabel)

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        view.addSubview(textStack)
    }

    private func setupConstraints() {
        cardsContainer.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-60)
            $0.width.equalTo(cardSize.width)
            $0.height.equalTo(cardSize.height)
        }

        moaCardLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(10)
            $0.centerX.equalToSuperview()
        }

        textStack.snp.makeConstraints {
            $0.top.equalTo(cardsContainer.snp.bottom).offset(36)
            $0.centerX.equalToSuperview()
        }
    }

    // anchorPoint를 건드리는 카드 3장만 manual frame
    private func layoutCardFrames() {
        for card in [cardLeft, cardRight, cardCenter] {
            card.frame = CGRect(origin: .zero, size: cardSize)
            card.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            card.center = CGPoint(x: cardSize.width / 2, y: cardSize.height)
        }
        let innerFrame = CGRect(x: innerInset, y: innerInset,
                                width: cardSize.width - innerInset * 2,
                                height: innerHeight)
        cardLeftInner.frame = innerFrame
        cardRightInner.frame = innerFrame
        cardCenterInner.frame = innerFrame
    }

    private func runAnimation(completion: (() -> Void)? = nil) {
        // 초기 transform — layoutCardFrames 이후에 세팅
        for card in [cardLeft, cardRight, cardCenter] {
            card.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }

        let spring = UISpringTimingParameters(dampingRatio: 0.72, initialVelocity: .zero)

        // step1: 센터 카드 등장
        let step1 = UIViewPropertyAnimator(duration: 0.5, timingParameters: spring)
        step1.addAnimations {
            self.cardCenter.alpha = 1
            self.cardCenter.transform = .identity// .scaledBy(x: 0.95, y: 0.95)
        }

        // step2: 좌우 fan-out
        let step2 = UIViewPropertyAnimator(duration: 0.6, timingParameters: spring)
        step2.addAnimations {
            self.cardLeft.alpha = 1
            self.cardLeft.transform = CGAffineTransform(rotationAngle: -.pi / 8)
                .scaledBy(x: 0.95, y: 0.95)
                .translatedBy(x: -12, y: -10)
            self.cardRight.alpha = 1
            self.cardRight.transform = CGAffineTransform(rotationAngle: .pi / 8)
                .scaledBy(x: 0.95, y: 0.95)
                .translatedBy(x: 12, y: -10)
        }

        // step3: 살짝 모이기 + 카드 내 moa 등장
        let step3 = UIViewPropertyAnimator(duration: 0.5, timingParameters: spring)
        step3.addAnimations {
            self.cardLeft.transform = CGAffineTransform(rotationAngle: -.pi / 16)
                .scaledBy(x: 0.92, y: 0.92)
                .translatedBy(x: -12, y: -10)
            self.cardRight.transform = CGAffineTransform(rotationAngle: .pi / 16)
                .scaledBy(x: 0.92, y: 0.92)
                .translatedBy(x: 12, y: -10)
        }
        step3.addAnimations({ self.moaCardLabel.alpha = 1 }, delayFactor: 0.4)

        // step4: 하단 타이틀 + 서브타이틀
        let step4 = UIViewPropertyAnimator(duration: 0.6, curve: .easeOut)
        step4.addAnimations { self.titleLabel.alpha = 1 }
        step4.addAnimations({ self.subtitleLabel.alpha = 1 }, delayFactor: 0.35)
        step4.addCompletion { _ in
            completion?()
        }

        // 체이닝
        step1.addCompletion { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { step2.startAnimation() }
        }
        step2.addCompletion { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { step3.startAnimation() }
        }
        step3.addCompletion { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { step4.startAnimation() }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            step1.startAnimation()
        }
    }

    private func makeCard() -> UIView {
        let view = UIView()
        view.backgroundColor = Theme.surface
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1.2
        view.layer.borderColor = Theme.strokeSoft.cgColor
        return view
    }
}
