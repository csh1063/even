//
//  OnboardingPageViewController.swift
//  Presentation
//
//  Created by sanghyeon on 5/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

final class OnboardingPageViewController: UIViewController {

    let index: Int
    private let page: OnboardingPage

    private let imageView = UIImageView()
//    private let gradientView = GradientView()
    private let textStack = UIStackView()

    init(page: OnboardingPage, index: Int) {
        self.page = page
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetAnimatableViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playEntranceAnimation()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = page.accentColor

        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: page.imageName, in: .module, with: nil)

        let titleLabel = UILabel()
        titleLabel.text = page.title
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = Theme.textPrimary//.white
        titleLabel.textAlignment = .center

        let descLabel = UILabel()
        descLabel.text = page.description
        descLabel.font = .systemFont(ofSize: 15, weight: .light)
        descLabel.textColor = Theme.textSecondary //UIColor.white.withAlphaComponent(0.85)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0

        textStack.axis = .vertical
        textStack.spacing = 12
        textStack.alignment = .center
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(descLabel)

        view.addSubview(imageView)
//        view.addSubview(gradientView)
        view.addSubview(textStack)

        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-60)
            $0.width.equalToSuperview().multipliedBy(0.9)
            $0.height.equalTo(imageView.snp.width)
        }

//        gradientView.snp.makeConstraints {
//            $0.leading.trailing.bottom.equalToSuperview()
//            $0.height.equalToSuperview().multipliedBy(0.45)
//        }

        textStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(140)
        }
    }

    // MARK: - Animation

    private func resetAnimatableViews() {
        imageView.alpha = 0
        imageView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        textStack.alpha = 0
        textStack.transform = CGAffineTransform(translationX: 0, y: 24)
    }

    private func playEntranceAnimation() {
        UIView.animate(
            withDuration: 0.55,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.3,
            options: .curveEaseOut
        ) {
            self.imageView.alpha = 1
            self.imageView.transform = .identity
        }

        UIView.animate(
            withDuration: 0.45,
            delay: 0.15,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: .curveEaseOut
        ) {
            self.textStack.alpha = 1
            self.textStack.transform = .identity
        }
    }
}

// MARK: - GradientView

final class GradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        gradientLayer.locations = [0, 1]
    }

    required init?(coder: NSCoder) { fatalError() }
}
