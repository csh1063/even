//
//  NaviBarView.swift
//  Presentation
//
//  Created by sanghyeon on 3/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Combine

// MARK: - NaviBarView

final class NaviBarView: UIView {

    private let type: NaviBarType

    private let blurView = UIView()
    private let coverView = UIView()
    private let stackView: UIStackView = {
        let stackView = UIStackView()

        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 4

        return stackView
    }()

    private var buttons: [NaviBarButton] = []

    private lazy var logoImageView = UIImageView()

    private lazy var titleLabel = UILabel()
    private lazy var messageLabel = UILabel()

    private let buttonTapSubject = PassthroughSubject<NaviBarButtonType, Never>()
    var publisher: AnyPublisher<NaviBarButtonType, Never> {
        buttonTapSubject.eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()
    private var buttonCancellables = Set<AnyCancellable>()

    init(
        type: NaviBarType = .title(.leading),
        isBlur: Bool = false
    ) {
        self.type = type

        super.init(frame: .zero)

        setupAppearance(isBlur: isBlur)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("NaviBarView does not support NSCoding.")
    }

    public func setTitle(_ title: String,
                         color: UIColor = Theme.textPrimary,
                         font: UIFont = .systemFont(ofSize: 20)) {
        self.titleLabel.text = title
        self.titleLabel.textColor = color
        self.titleLabel.font = font
        self.titleLabel.numberOfLines = 1
        self.titleLabel.lineBreakMode = .byTruncatingTail
    }

    public func setMessage(_ message: String,
                           color: UIColor = Theme.textPrimary,
                           font: UIFont = .systemFont(ofSize: 20)) {
        self.messageLabel.text = message
        self.messageLabel.textColor = color
        self.messageLabel.font = font
    }

    public func setHeight(_ height: CGFloat) {

        stackView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }

    public func setEnabled(_ enabled: Bool, for type: NaviBarButtonType) {
        buttons.first(where: { $0.type == type })?.setEnabled(enabled)
    }

    public func addButtons(_ settings: [NaviButtonSetting]) {
        self.clearButtons()
        self.buttonCancellables.removeAll()
        self.buttons = settings.map { setting in

            let button = NaviBarButton(type: setting.type)
            button.tintAdjustmentMode = .normal
//            button.buttonTintColor = setting.color

            button.publisher
                .sink { [weak self] type in self?.buttonTapSubject.send(type) }
                .store(in: &buttonCancellables)

            if setting.isLeft {
                self.stackView.insertArrangedSubview(button, at: 0)
                button.snp.makeConstraints { make in
                    make.width.equalTo(44)
                }
                self.coverView.snp.updateConstraints { make in
                    make.leading.equalToSuperview()
                }
                return button
            } else {
                self.stackView.addArrangedSubview(button)
                button.snp.makeConstraints { make in
                    make.width.equalTo(44)
                }
//                self?.coverView.snp.updateConstraints { make in
//                    make.trailing.equalToSuperview()
//                }
                return button
            }
        }
    }

    // MARK: - Setup
    private func setupAppearance(isBlur: Bool) {
        if isBlur {
            backgroundColor = Theme.background.withAlphaComponent(0.7)
            blurView.setBlur(style: .light)
        } else {
            backgroundColor = Theme.background
        }
    }

    private func setupView() {
        addSubview(blurView)
        addSubview(coverView)
        addSubview(stackView)
        backgroundColor = .black.withAlphaComponent(0.01)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        coverView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(20)
            make.bottom.lessThanOrEqualToSuperview()
            make.height.equalTo(44)
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalTo(coverView)
        }

        switch self.type {
        case .logo:
            logoImageView.contentMode = .scaleAspectFit
            self.addSubview(logoImageView)
            logoImageView.snp.makeConstraints { make in
                make.center.equalTo(self)
            }
        case .title(let titleAlign):
            switch titleAlign {
            case .center:
                titleLabel.textAlignment = .center

                self.addSubview(titleLabel)
                titleLabel.snp.makeConstraints { make in
                    make.center.equalTo(stackView)
                }
                let emptyView = UIView(backgroundColor: .clear)
                stackView.addArrangedSubview(emptyView)
            case .leading:
                titleLabel.textAlignment = .left
                stackView.addArrangedSubview(titleLabel)
                coverView.addSubview(messageLabel)
                messageLabel.snp.makeConstraints { make in
                    make.top.equalTo(coverView.snp.bottom).offset(6)
                    make.bottom.equalTo(self).offset(-8)
                    make.leading.equalTo(titleLabel)
                }
            }
        }
    }

    /// 팬 제스처를 뷰에 붙이고 began/ended 상태에 따라 버튼 하이라이트를 제어
    private func bindPanGesture(to targetView: UIView, button: UIButton) {
        let panGesture = UIPanGestureRecognizer()
        targetView.addGestureRecognizer(panGesture)

        panGesture.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { gesture in
                switch gesture.state {
                case .began:
                    button.isHighlighted = true
                case .ended:
                    button.isHighlighted = false
                    button.sendActions(for: .allEvents)
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func clearButtons() {
        for subview in stackView.arrangedSubviews where subview is NaviBarButton {
            subview.removeFromSuperview()
        }
    }
}
