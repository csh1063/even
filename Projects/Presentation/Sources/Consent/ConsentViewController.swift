//
//  ConsentViewController.swift
//  Presentation
//
//  Created by sanghyeon on 5/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import SafariServices

final class ConsentViewController: UIViewController {

    // MARK: - Callbacks
    var onConsented: (() -> Void)?
    var onDismissed: (() -> Void)?

    // MARK: - State
    private var isTermsAgreed = false {
        didSet { updateConfirmButton() }
    }
    private var isPrivacyAgreed = false {
        didSet { updateConfirmButton() }
    }

    private var isAllAgreed: Bool {
        isTermsAgreed && isPrivacyAgreed
    }

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private lazy var logoView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var logo: UIImageView = {
        let image = UIImage(named: "icon", in: .module, with: nil)
        let imageView = UIImageView(image: image)
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var appNameLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "모아", bundle: .module)
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = Theme.textPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "서비스 이용을 위해\n아래 내용에 동의해 주세요", bundle: .module)
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = Theme.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "모아 앱 사용을 위하여 필수 약관에 동의해 주세요", bundle: .module)
//        label.text = "동의하지 않아도 일부 기능을 사용할 수 있습니다"
        label.font = .systemFont(ofSize: 13)
        label.textColor = Theme.textSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var allAgreeView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surface
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var allAgreeCheckbox = makeCheckbox()

    private lazy var allAgreeLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "전체 동의", bundle: .module)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Theme.textPrimary
        return label
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.strokeSoft
        return view
    }()

    private lazy var termsRow = makeConsentRow(
        title: String(localized: "(필수) 서비스 이용약관", bundle: .module),
        urlText: String(localized: "전문 보기", bundle: .module)
    )

    private lazy var privacyRow = makeConsentRow(
        title: String(localized: "(필수) 개인정보 처리방침", bundle: .module),
        urlText: String(localized: "전문 보기", bundle: .module)
    )

    private lazy var termsCheckbox = makeCheckbox()
    private lazy var privacyCheckbox = makeCheckbox()

    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(String(localized: "확인", bundle: .module), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Theme.primary.withAlphaComponent(0.4)
        button.layer.cornerRadius = 14
        button.isEnabled = false
        button.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = Theme.background

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // Logo
        contentView.addSubview(logoView)
        logoView.addSubview(logo)
        logoView.addSubview(appNameLabel)

        logoView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(48)
            $0.centerX.equalToSuperview()
        }

        logo.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(200)
        }

        appNameLabel.snp.makeConstraints {
            $0.top.equalTo(logo.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        // Title
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(logoView.snp.bottom).offset(32)
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }

        // All agree
        contentView.addSubview(allAgreeView)
        allAgreeView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        allAgreeView.addSubview(allAgreeCheckbox)
        allAgreeCheckbox.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.equalToSuperview().offset(16)
//            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        allAgreeView.addSubview(allAgreeLabel)
        allAgreeLabel.snp.makeConstraints {
            $0.leading.equalTo(allAgreeCheckbox.snp.trailing).offset(10)
            $0.centerY.equalTo(allAgreeCheckbox)
//            $0.top.equalToSuperview().inset(16)
        }

        // Divider
        allAgreeView.addSubview(divider)
        divider.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
            $0.top.equalTo(allAgreeLabel.snp.bottom).offset(16)
        }

        // Terms row
        let (termsContainer, termsLink) = termsRow
        allAgreeView.addSubview(termsContainer)
        allAgreeView.addSubview(termsCheckbox)

        termsCheckbox.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(divider.snp.bottom).offset(14)
            $0.width.height.equalTo(22)
        }

        termsContainer.snp.makeConstraints {
            $0.leading.equalTo(termsCheckbox.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(termsCheckbox)
        }

        // Privacy row
        let (privacyContainer, privacyLink) = privacyRow
        allAgreeView.addSubview(privacyContainer)
        allAgreeView.addSubview(privacyCheckbox)

        privacyCheckbox.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(termsCheckbox.snp.bottom).offset(14)
            $0.width.height.equalTo(22)
            $0.bottom.equalToSuperview().inset(16)
        }

        privacyContainer.snp.makeConstraints {
            $0.leading.equalTo(privacyCheckbox.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(privacyCheckbox)
        }

        // Buttons
        contentView.addSubview(confirmButton)
        confirmButton.snp.makeConstraints {
            $0.top.equalTo(allAgreeView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(54)
            $0.bottom.equalToSuperview().inset(24)
        }

        // 링크 버튼 태그로 구분
        termsLink.tag = 0
        privacyLink.tag = 1
        termsLink.addTarget(self, action: #selector(linkTapped(_:)), for: .touchUpInside)
        privacyLink.addTarget(self, action: #selector(linkTapped(_:)), for: .touchUpInside)

        // 체크박스 / 전체동의 탭
        let allAgreeTap = UITapGestureRecognizer(target: self, action: #selector(allAgreeTapped))
        allAgreeCheckbox.addGestureRecognizer(allAgreeTap)
        allAgreeCheckbox.isUserInteractionEnabled = true

        let allAgreeLabelTap = UITapGestureRecognizer(target: self, action: #selector(allAgreeTapped))
        allAgreeLabel.addGestureRecognizer(allAgreeLabelTap)
        allAgreeLabel.isUserInteractionEnabled = true

        let termsTap = UITapGestureRecognizer(target: self, action: #selector(termsCheckTapped))
        termsCheckbox.addGestureRecognizer(termsTap)
        termsCheckbox.isUserInteractionEnabled = true

        let privacyTap = UITapGestureRecognizer(target: self, action: #selector(privacyCheckTapped))
        privacyCheckbox.addGestureRecognizer(privacyTap)
        privacyCheckbox.isUserInteractionEnabled = true
    }

    private func setupActions() {}

    // MARK: - Factory
    private func makeCheckbox() -> UIView {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.layer.borderWidth = 1.5
        view.layer.borderColor = Theme.strokeSoft.cgColor
        view.backgroundColor = .white

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
        checkmark.tintColor = .white
        checkmark.contentMode = .scaleAspectFit
        checkmark.isHidden = true
        checkmark.tag = 99
        view.addSubview(checkmark)
        checkmark.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(13)
        }
        return view
    }

    private func makeConsentRow(title: String, urlText: String) -> (UIView, UIButton) {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = Theme.textSecondary

        let linkButton = UIButton(type: .system)
        linkButton.setTitle(urlText, for: .normal)
        linkButton.titleLabel?.font = .systemFont(ofSize: 12)
        linkButton.setTitleColor(Theme.textSecondary, for: .normal)

        container.addSubview(titleLabel)
        container.addSubview(linkButton)

        titleLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.top.bottom.equalToSuperview()
        }

        linkButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }

        return (container, linkButton)
    }

    // MARK: - Checkbox State
    private func setCheckbox(_ view: UIView, checked: Bool) {
        if checked {
            view.backgroundColor = Theme.primary
            view.layer.borderColor = Theme.strokeSoft.cgColor
        } else {
            view.backgroundColor = Theme.surface
            view.layer.borderColor = Theme.strokeSoft.cgColor
        }
        view.subviews.first(where: { $0.tag == 99 })?.isHidden = !checked
    }

    private func updateAllAgreeCheckbox() {
        setCheckbox(allAgreeCheckbox, checked: isAllAgreed)
    }

    private func updateConfirmButton() {
        let enabled = isAllAgreed
        confirmButton.isEnabled = enabled
        UIView.animate(withDuration: 0.2) {
            self.confirmButton.backgroundColor = enabled
            ? Theme.primary
            : Theme.primary.withAlphaComponent(0.4)
        }
    }

    // MARK: - Actions
    @objc private func allAgreeTapped() {
        let newValue = !isAllAgreed
        isTermsAgreed = newValue
        isPrivacyAgreed = newValue
        setCheckbox(termsCheckbox, checked: newValue)
        setCheckbox(privacyCheckbox, checked: newValue)
        updateAllAgreeCheckbox()
    }

    @objc private func termsCheckTapped() {
        isTermsAgreed.toggle()
        setCheckbox(termsCheckbox, checked: isTermsAgreed)
        updateAllAgreeCheckbox()
    }

    @objc private func privacyCheckTapped() {
        isPrivacyAgreed.toggle()
        setCheckbox(privacyCheckbox, checked: isPrivacyAgreed)
        updateAllAgreeCheckbox()
    }

    @objc private func linkTapped(_ sender: UIButton) {
        // GitHub Pages URL로 교체
        let urlString = sender.tag == 0
            ? "https://csh1063.github.io/moa-web/terms-of-service.html"
            : "https://csh1063.github.io/moa-web/privacy-policy.html"
        guard let url = URL(string: urlString) else { return }

        let safariVC = SFSafariViewController(url: url)  // import SafariServices 필요
        present(safariVC, animated: true)
    }

    @objc private func confirmTapped() {
//        UserDefaults.standard.set(true, forKey: "hasAgreedToTerms")
        onConsented?()
        self.dismiss(animated: true)
    }
}
