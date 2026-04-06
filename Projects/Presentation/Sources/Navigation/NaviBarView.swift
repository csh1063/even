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
    private lazy var leftType: NaviBarButtonType = .none
//    private lazy var rightTypes: [NaviBarButtonType] = []
    
    private let blurView = UIView()
    private let coverView = UIView()
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.spacing = 4
        
        return stackView
    }()
    
    private lazy var leftButton: NaviBarButton = {
        NaviBarButton(type: self.leftType)
    }()
    private var rightButtons: [NaviBarButton] = []
//    private lazy var innerRightButton: NaviBarButton = {
//        NaviBarButton(type: self.innerRightType)
//    }()
    
    private lazy var logoImageView = UIImageView()
    
    private lazy var titleLabel: UILabel = UILabel()
    
    var leftPublisher: AnyPublisher<NaviBarButtonType, Never> {
        leftButton.publisher.eraseToAnyPublisher()
    }
    
    var rightPublisher: AnyPublisher<NaviBarButtonType, Never> {
        let publishers = rightButtons.map { $0.publisher }
        return Publishers.MergeMany(publishers).eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

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
                         color: UIColor = .Theme.primary,
                         font: UIFont = .systemFont(ofSize: 20)) {
        self.titleLabel.text = title
        self.titleLabel.textColor = color
        self.titleLabel.font = font
    }
    
    public func setHeight(_ height: CGFloat) {

        stackView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }
    
    public func addLeftButton(_ type: NaviBarButtonType, color: UIColor = .Theme.primary) {
        
        self.leftType = type
        self.leftButton.buttonTintColor = color
        
        if leftType != .none {
            stackView.insertArrangedSubview(leftButton, at: 0)
            leftButton.snp.makeConstraints { make in
                make.width.equalTo(44)
            }
            coverView.snp.updateConstraints { make in
                make.leading.equalToSuperview()
            }
        }
    }
    
    public func addRightButtons(
        _ settings: [(NaviBarButtonType, UIColor)]
    ) {
        self.rightButtons = settings.map { [weak self] (type, color) in
            let button = NaviBarButton(type: type)
            button.buttonTintColor = color
            
            self?.stackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.width.equalTo(44)
            }
            return button
        }
        
        coverView.snp.updateConstraints { make in
            make.trailing.equalToSuperview()
        }
    }

    // MARK: - Setup
    private func setupAppearance(isBlur: Bool) {
        if isBlur {
            backgroundColor = UIColor.Theme.background.withAlphaComponent(0.7)
            blurView.setBlur(style: .light)
        } else {
            backgroundColor = UIColor.Theme.background
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
            make.top.equalTo(self.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
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
}
