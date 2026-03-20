//
//  TitleBarView.swift
//  Presentation
//
//  Created by sanghyeon on 3/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit
import SnapKit
import Combine

// MARK: - TitleBarView

final class TitleBarView: UIView {

    // MARK: - Public Properties

    let leftType: TitleLeftType
    let rightType: TitleRightType

    private(set) var viewModel: TitleBarViewModel?

    // MARK: - UI Components

    let blurView = UIView()

    let outerLeftButton = UIButton()
    let outerRightButton = UIButton()
    let newRightImageView = UIImageView(image: UIImage(named: ""))

    let logoImageView = UIImageView(image: UIImage(named: ""))
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Theme.midnight
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Private Properties

    private let outerLeftBackView = UIView()
    private let outerRightBackView = UIView()

    private weak var delegate: TitleBarViewDelegate?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        self.leftType = .clear
        self.rightType = .clear
        super.init(frame: .zero)
    }

    init(
        title: String,
        delegate: TitleBarViewDelegate,
        left: TitleLeftType = .clear,
        right: TitleRightType = .clear,
        leftButtonTitle: String = "",
        rightButtonTitle: String = "",
        isLogo: Bool = false,
        isBlur: Bool = true
    ) {
        self.leftType = left
        self.rightType = right
        self.delegate = delegate

        super.init(frame: .zero)

        setupAppearance(isBlur: isBlur)
        titleLabel.text = title

        setupViewHierarchy()
        setupConstraints()
        configureLeftButton(left: left, leftButtonTitle: leftButtonTitle)
        configureRightButton(right: right, rightButtonTitle: rightButtonTitle)

        if isLogo { setupLogoLayout() }

        newRightImageView.isHidden = true

        let viewModel = TitleBarViewModel(view: self)
        bindButtons(viewModel: viewModel)
        self.viewModel = viewModel
    }

    required init?(coder: NSCoder) {
        fatalError("TitleBarView does not support NSCoding.")
    }

    // MARK: - Setup

    private func setupAppearance(isBlur: Bool) {
        if isBlur {
            backgroundColor = UIColor.Theme.white.withAlphaComponent(0.7)
            blurView.setBlur(style: .light)
        } else {
            backgroundColor = UIColor.Theme.white
        }
    }

    private func setupViewHierarchy() {
        addSubview(blurView)
        addSubview(titleLabel)

        if leftType != .clear {
            addSubview(outerLeftBackView)
            addSubview(outerLeftButton)
        }

        if rightType != .clear {
            addSubview(outerRightBackView)
            addSubview(outerRightButton)
            addSubview(newRightImageView)
        }
    }

    private func setupConstraints() {
//        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        blurView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaInsets)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.safeAreaInsets)
            make.height.equalTo(44)
        }

        if leftType != .clear {
            setupLeftButtonConstraints()
            outerLeftBackView.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.top.equalTo(self.safeAreaInsets)
                make.right.bottom.height.equalTo(outerLeftButton)
            }
        }

        if rightType != .clear {
            setupRightButtonConstraints()
            outerRightBackView.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.top.equalTo(self.safeAreaInsets)
                make.left.bottom.height.equalTo(outerRightButton)
            }
            newRightImageView.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-12)
                make.bottom.equalToSuperview().offset(-8)
                make.width.height.equalTo(10)
            }
        }
    }

    private func setupLogoLayout() {
        titleLabel.isHidden = true
        logoImageView.contentMode = .scaleAspectFit
        addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.safeAreaInsets).offset(11)
            make.height.equalTo(23)
        }
    }

    // MARK: - Button Binding (Combine)

    private func bindButtons(viewModel: TitleBarViewModel) {
        // 왼쪽 버튼 탭
        outerLeftButton.tapPublisher
            .sink { [weak self, weak viewModel] _ in
                guard let self, let viewModel else { return }
                self.delegate?.outerLeftButtonTapped(viewModel: viewModel, sender: self.outerLeftButton)
            }
            .store(in: &cancellables)

        // 오른쪽 버튼 탭
        outerRightButton.tapPublisher
            .sink { [weak self, weak viewModel] _ in
                guard let self, let viewModel else { return }
                self.delegate?.outerRightButtonTapped(viewModel: viewModel, sender: self.outerRightButton)
            }
            .store(in: &cancellables)

        // 왼쪽 백뷰 팬 제스처 → 버튼 하이라이트 연동
        bindPanGesture(to: outerLeftBackView, button: outerLeftButton)

        // 오른쪽 백뷰 팬 제스처 → 버튼 하이라이트 연동
        bindPanGesture(to: outerRightBackView, button: outerRightButton)
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

// MARK: - Left Button Configuration

private extension TitleBarView {

    func setupLeftButtonConstraints() {
//        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        outerLeftButton.snp.makeConstraints { make in
            switch leftType {
            case .back:
                make.left.equalToSuperview().offset(10)
                if rightType == .clear { make.right.equalToSuperview().offset(-20) }
            case .filter, .report:
                make.left.equalToSuperview().offset(20)
                make.width.equalTo(44)
            default:
                make.left.equalToSuperview().offset(10)
                make.width.equalTo(44)
            }
            make.top.equalTo(self.safeAreaInsets)
            make.height.equalTo(44)
        }
    }

    func configureLeftButton(left: TitleLeftType, leftButtonTitle: String) {
//        switch left {
//        case .back:
//            outerLeftButton.setNaviButtonForm(title: leftButtonTitle, image: UIImage.SsoldotAssets.iconBackSelected)
//        case .cancel:
//            outerLeftButton.setNaviButtonForm(title: leftButtonTitle, image: UIImage.SsoldotAssets.iconCancelSelected)
//        case .filter:
//            outerLeftButton
//                .withImage(UIImage.SsoldotAssets.navigationFilter, for: .normal)
//                .withImage(UIImage.SsoldotAssets.navigationFilterSelected, for: .highlighted)
//                .setImage(UIImage.SsoldotAssets.navigationFilterSelected, for: .selected)
//        case .report:
//            outerLeftButton
//                .withImage(UIImage.SsoldotAssets.navigationReport, for: .normal)
//                .setImage(UIImage.SsoldotAssets.navigationReportSelected, for: .highlighted)
//        case .clear:
//            break
//        }
    }
}

// MARK: - Right Button Configuration

private extension TitleBarView {

    func setupRightButtonConstraints() {
//        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        outerRightButton.snp.makeConstraints { make in
            switch rightType {
            case .next, .clearText:
                make.right.equalToSuperview().offset(-10)
            case .finder, .setting, .write:
                make.right.equalToSuperview().offset(-20)
                make.width.equalTo(44)
            default:
                make.right.equalToSuperview().offset(-10)
                make.width.equalTo(44)
            }
            make.top.equalTo(self.safeAreaInsets)
            make.height.equalTo(44)
        }
    }

    func configureRightButton(right: TitleRightType, rightButtonTitle: String) {
//        switch right {
//        case .next:
//            outerRightButton.setNaviButtonForm(
//                title: rightButtonTitle,
//                image: UIImage.SsoldotAssets.iconNextSelected,
//                disabledImage: UIImage.SsoldotAssets.iconNext,
//                contentHorizontalAlignment: .right
//            )
//        case .clearText:
//            outerRightButton
//                .withTitle("Clear".localized, for: .normal)
//                .withTitleColor(UIColor.SsoldotTheme.neonRed, for: .normal)
//                .withTitleLabelFont(UIFont.regularLocalizedFont(ofSize: 16))
//                .withTitleAlignment(.right)
//        case .confirm:
//            outerRightButton
//                .withImage(UIImage.SsoldotAssets.iconConfirm, for: .disabled)
//                .setImage(UIImage.SsoldotAssets.iconConfirmSelected, for: .normal)
//        case .toggleList:
//            outerRightButton
//                .withImage(UIImage.SsoldotAssets.iconList, for: .normal)
//                .withImage(UIImage.SsoldotAssets.iconListSelected, for: .selected)
//                .setImage(UIImage.SsoldotAssets.iconListSelected, for: .highlighted)
//        case .finder:
//            outerRightButton
//                .withImage(UIImage.SsoldotAssets.navigationFinder, for: .normal)
//                .withImage(UIImage.SsoldotAssets.navigationFinderSelected, for: .selected)
//                .setImage(UIImage.SsoldotAssets.navigationFinderSelected, for: .highlighted)
//        case .setting:
//            outerRightButton
//                .withImage(UIImage.SsoldotAssets.navigationSetting, for: .normal)
//                .setImage(UIImage.SsoldotAssets.navigationSettingSelected, for: .highlighted)
//        case .write:
//            outerRightButton
//                .withImage(UIImage.SsoldotAssets.navigationWrite, for: .normal)
//                .setImage(UIImage.SsoldotAssets.navigationWriteSelected, for: .highlighted)
//        case .clear:
//            break
//        }
    }
}
