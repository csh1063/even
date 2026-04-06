//
//  AlertViewController.swift
//  Presentation
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit
import SnapKit

final class AlertViewController: BaseViewController {

    private let viewModel: AlertViewModel
    private let onDismiss: () -> Void  // AlertManager.cleanup 호출용

    private let dimView: UIView = {
        let dimView = UIView()
        dimView.backgroundColor = .black.withAlphaComponent(0.4)
        dimView.alpha = 0
        return dimView
    }()

    private let containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .Theme.background
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        containerView.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        containerView.alpha = 0
        return containerView
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = .Theme.text
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    private let messageLabel: UILabel = {
        let messageLabel = UILabel()
        messageLabel.textColor = .Theme.text
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        return messageLabel
    }()

    private let buttonStack: UIStackView = {
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 0
        return buttonStack
    }()

    init(viewModel: AlertViewModel, onDismiss: @escaping () -> Void) {
        
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("AlertViewController does not support NSCoding.") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configure()
        addDimTapGestureIfNeeded()
        
        self.view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(dimView)
        view.addSubview(containerView)

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }

        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textStack.axis    = .vertical
        textStack.spacing = 6
        textStack.alignment = .center

        let topSeparator = makeSeparator(.vertical, height: 1)

        containerView.addSubview(textStack)
        containerView.addSubview(topSeparator)
        containerView.addSubview(buttonStack)

        textStack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        topSeparator.snp.makeConstraints { make in
            make.top.equalTo(textStack.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(topSeparator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Configure
    private func configure() {
        titleLabel.text   = viewModel.title
        messageLabel.text = viewModel.message
        messageLabel.isHidden = viewModel.message == nil
        
        if viewModel.buttons.count != 2 {
            buttonStack.axis = .vertical
            viewModel.buttons.enumerated().forEach { index, config in
                if index > 0 {
                    buttonStack.addArrangedSubview(makeSeparator(.vertical, inset: 16))
                }
                buttonStack.addArrangedSubview(makeButton(for: config, index: index))
            }
        } else {
            buttonStack.axis = .horizontal
            buttonStack.distribution = .fillProportionally
            viewModel.buttons.enumerated().forEach { index, config in
                if index > 0 {
                    buttonStack.addArrangedSubview(makeSeparator(.horizontal, height: 1, inset: 4))
                }
                buttonStack.addArrangedSubview(makeButton(for: config, index: index))
            }
        }
    }

    private func makeButton(for config: AlertButtonConfig, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(config.title, for: .normal)
        button.setTitleColor(config.style.titleColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: config.style.fontWeight)
        button.tag = index
        button.snp.makeConstraints { make in
            make.height.equalTo(51.5)
        }
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeSeparator(_ axis: NSLayoutConstraint.Axis, height: CGFloat = 0.5, inset: CGFloat = 12) -> UIView {
        let backView = UIView()
        let view = UIView()
        view.backgroundColor = .Theme.tertiary.withAlphaComponent(0.2)
        backView.addSubview(view)
        switch axis {
        case .horizontal:
            backView.snp.makeConstraints { make in
                make.width.equalTo(height)
            }
            view.snp.makeConstraints { make in
                make.width.equalTo(height)
                make.top.bottom.equalTo(backView).inset(inset)
            }
        case .vertical:
            backView.snp.makeConstraints { make in
                make.height.equalTo(height)
            }
            view.snp.makeConstraints { make in
                make.height.equalTo(height)
                make.leading.trailing.equalTo(backView).inset(inset)
            }
        @unknown default: break
        }
        return backView
    }

    // MARK: - Actions
    @objc private func buttonTapped(_ sender: UIButton) {
        let config = viewModel.buttons[sender.tag]
        performDismiss(action: config.action)
    }

    private func addDimTapGestureIfNeeded() {
        guard viewModel.buttons.contains(where: { $0.style == .cancel }) else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dimTapped))
        dimView.addGestureRecognizer(tap)
    }

    @objc private func dimTapped() {
        let cancelAction = viewModel.buttons.first(where: { $0.style == .cancel })?.action
        performDismiss(action: cancelAction)
    }

    private func performDismiss(action: (() -> Void)?) {
        animateOut { [weak self] in
            self?.dismiss(animated: false) {
                action?()
                self?.onDismiss()  // 큐에 다음 alert 처리 트리거
            }
        }
    }

    // MARK: - Animation
    private func animateIn() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5
        ) {
            self.dimView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2) {
            self.dimView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            completion()
        }
    }
}
