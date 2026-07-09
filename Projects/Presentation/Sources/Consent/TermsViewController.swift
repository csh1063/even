//
//  TermsItem.swift
//  Presentation
//
//  Created by sanghyeon on 5/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import SafariServices

// MARK: - Model

struct TermsItem {
    let id: String
    let title: String
    let isRequired: Bool
    let url: URL
    var isAgreed: Bool = false
}

// MARK: - TermsViewController

final class TermsViewController: UIViewController {

    // MARK: - Properties

    private var items: [TermsItem] = [
        TermsItem(
            id: "terms",
            title: "서비스 이용약관",
            isRequired: true,
            url: URL(string: "https://csh1063.github.io/moa-web/terms-of-service.html")!
        ),
        TermsItem(
            id: "privacy",
            title: "개인정보처리방침",
            isRequired: true,
            url: URL(string: "https://csh1063.github.io/moa-web/privacy-policy.html")!
        )
    ]

    private var isAllAgreed: Bool {
        items.allSatisfy { $0.isAgreed }
    }

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "모아 시작하기"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = Theme.primary
        return label
    }()

    private let subHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "서비스 이용을 위해\n약관에 동의해주세요"
        label.font = .systemFont(ofSize: 28)
        label.textColor = Theme.textSecondary
        label.numberOfLines = 2
        return label
    }()

    private let allAgreeContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surfaceWarm
        view.layer.cornerRadius = 14
        return view
    }()

    private let allAgreeCheckbox = CheckboxView()

    private let allAgreeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "전체 동의"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.textPrimary
        return label
    }()

    private let allAgreeSubLabel: UILabel = {
        let label = UILabel()
        label.text = "필수 항목에 모두 동의합니다"
        label.font = .systemFont(ofSize: 13)
        label.textColor = Theme.textTertiary
        return label
    }()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.divider
        return view
    }()

    private let itemsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        return sv
    }()

    private let confirmButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "동의하고 시작하기"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.primary
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { container in
            var c = container
            c.font = .systemFont(ofSize: 16, weight: .semibold)
            return c
        }
        let button = UIButton(configuration: config)
        button.isEnabled = false
        button.alpha = 0.4
        return button
    }()

    var onConsented: (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        setupUI()
        setupConstraints()
        setupActions()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(confirmButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [appNameLabel, subHeaderLabel, allAgreeContainer, divider, itemsStackView].forEach {
            contentView.addSubview($0)
        }

        [allAgreeCheckbox, allAgreeTitleLabel, allAgreeSubLabel].forEach {
            allAgreeContainer.addSubview($0)
        }

        items.forEach { item in
            let row = TermsRowView(item: item)
            row.onToggle = { [weak self] in self?.toggleItem(id: item.id) }
            row.onDetail = { [weak self] in self?.showDetail(item: item) }
            itemsStackView.addArrangedSubview(row)
        }
    }

    private func setupConstraints() {
        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(54)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(confirmButton.snp.top).offset(-12)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        appNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(36)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        subHeaderLabel.snp.makeConstraints {
            $0.top.equalTo(appNameLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        allAgreeContainer.snp.makeConstraints {
            $0.top.equalTo(subHeaderLabel.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(72)
        }

        allAgreeCheckbox.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        allAgreeTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(allAgreeCheckbox.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(16)
        }

        allAgreeSubLabel.snp.makeConstraints {
            $0.leading.equalTo(allAgreeCheckbox.snp.trailing).offset(12)
            $0.top.equalTo(allAgreeTitleLabel.snp.bottom).offset(4)
        }

        divider.snp.makeConstraints {
            $0.top.equalTo(allAgreeContainer.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(1)
        }

        itemsStackView.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    private func setupActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(allAgreeTapped))
        allAgreeContainer.addGestureRecognizer(tap)
        allAgreeContainer.isUserInteractionEnabled = true

        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func allAgreeTapped() {
        let newState = !isAllAgreed
        for i in items.indices { items[i].isAgreed = newState }
        updateAllRows()
        updateAllAgreeState()
    }

    @objc private func confirmTapped() {
        // 다음 화면으로 이동
        self.onConsented?()
        self.dismiss(animated: true)
    }

    private func toggleItem(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isAgreed.toggle()
        updateAllRows()
        updateAllAgreeState()
    }

    private func showDetail(item: TermsItem) {
        let safariVC = SFSafariViewController(url: item.url)
        safariVC.preferredControlTintColor = Theme.primary
        present(safariVC, animated: true)
    }

    // MARK: - Update

    private func updateAllAgreeState() {
        allAgreeCheckbox.setChecked(isAllAgreed, animated: true)

        UIView.animate(withDuration: 0.2) {
            self.allAgreeContainer.backgroundColor = self.isAllAgreed
                ? Theme.primary.withAlphaComponent(0.12)
                : Theme.surfaceWarm
        }

        confirmButton.isEnabled = isAllAgreed
        UIView.animate(withDuration: 0.2) {
            self.confirmButton.alpha = self.isAllAgreed ? 1.0 : 0.4
        }
    }

    private func updateAllRows() {
        itemsStackView.arrangedSubviews
            .compactMap { $0 as? TermsRowView }
            .enumerated()
            .forEach { index, row in row.update(item: items[index]) }
    }
}

// MARK: - TermsRowView

final class TermsRowView: UIView {

    var onToggle: (() -> Void)?
    var onDetail: (() -> Void)?

    private var item: TermsItem

    private let checkbox = CheckboxView()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = Theme.primary
        label.text = "필수"
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = Theme.textPrimary
        return label
    }()

    private let chevronButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = Theme.textTertiary
        return button
    }()

    // MARK: - Init

    init(item: TermsItem) {
        self.item = item
        super.init(frame: .zero)
        setup()
        update(item: item)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        [checkbox, badgeLabel, titleLabel, chevronButton].forEach { addSubview($0) }

        snp.makeConstraints {
            $0.height.equalTo(56)
        }

        checkbox.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        badgeLabel.snp.makeConstraints {
            $0.leading.equalTo(checkbox.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(badgeLabel.snp.trailing).offset(6)
            $0.centerY.equalToSuperview()
        }

        chevronButton.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true

        chevronButton.addTarget(self, action: #selector(detailTapped), for: .touchUpInside)
    }

    // MARK: - Update

    func update(item: TermsItem) {
        self.item = item
        titleLabel.text = item.title
        checkbox.setChecked(item.isAgreed, animated: true)
    }

    // MARK: - Actions

    @objc private func rowTapped() { onToggle?() }
    @objc private func detailTapped() { onDetail?() }
}

// MARK: - CheckboxView

final class CheckboxView: UIView {

    private var isChecked = false
    private let circleLayer = CAShapeLayer()
    private let checkLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(circleLayer)
        layer.addSublayer(checkLayer)
        updateAppearance(animated: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = bounds
        circleLayer.frame = rect
        circleLayer.path = UIBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).cgPath
        checkLayer.frame = rect
        updateCheckPath()
    }

    private func updateCheckPath() {
        let w = bounds.width, h = bounds.height
        let path = UIBezierPath()
        path.move(to: CGPoint(x: w * 0.22, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.7))
        path.addLine(to: CGPoint(x: w * 0.76, y: h * 0.3))
        checkLayer.path = path.cgPath
        checkLayer.fillColor = UIColor.clear.cgColor
        checkLayer.strokeColor = UIColor.white.cgColor
        checkLayer.lineWidth = 2
        checkLayer.lineCap = .round
        checkLayer.lineJoin = .round
    }

    func setChecked(_ checked: Bool, animated: Bool) {
        guard isChecked != checked else { return }
        isChecked = checked
        updateAppearance(animated: animated)
    }

    private func updateAppearance(animated: Bool) {
        let targetColor = isChecked ? Theme.primary.cgColor : Theme.strokeSoft.cgColor

        if animated {
            let colorAnim = CABasicAnimation(keyPath: "fillColor")
            colorAnim.fromValue = circleLayer.fillColor
            colorAnim.toValue = targetColor
            colorAnim.duration = 0.2
            colorAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            circleLayer.add(colorAnim, forKey: "fill")

            if isChecked {
                let strokeAnim = CABasicAnimation(keyPath: "strokeEnd")
                strokeAnim.fromValue = 0
                strokeAnim.toValue = 1
                strokeAnim.duration = 0.2
                strokeAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
                checkLayer.add(strokeAnim, forKey: "stroke")
            }
        }

        circleLayer.fillColor = targetColor
        circleLayer.strokeColor = UIColor.clear.cgColor
        checkLayer.strokeEnd = isChecked ? 1 : 0
    }
}
