//
//  AlbumOptionsSheet.swift
//  Presentation
//
//  Created by sanghyeon on 4/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Combine

// MARK: - OptionRowConfig

struct OptionRowConfig {
    enum Style {
        case normal
        case destructive
    }

    let icon: String
    let title: String
    let style: Style
    let action: () -> Void
}

// MARK: - SelectionSheet

final class SelectionSheet: UIViewController {

    // MARK: - Properties

    private let sheetTitle: String
    private let sheetSubtitle: String?
    private let options: [OptionRowConfig]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private let grabberView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.strokeSoft
        v.layer.cornerRadius = 2.5
        return v
    }()

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 20, weight: .bold)
        lb.textColor = Theme.textPrimary
        return lb
    }()

    private let subtitleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 14, weight: .regular)
        lb.textColor = Theme.textSecondary
        return lb
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private lazy var rowStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        return sv
    }()

    // MARK: - Init

    init(title: String, subtitle: String? = nil, options: [OptionRowConfig]) {
        self.sheetTitle = title
        self.sheetSubtitle = subtitle
        self.options = options
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("SelectionSheet does not support NSCoding.")
    }

    // MARK: - Detent

    /// 옵션 개수에 맞춰 시트가 딱 맞게 늘어나도록 계산한 높이 — 항목이 많아지면 화면의 80%에서 멈추고
    /// 그 이상은 scrollView가 스크롤로 처리한다.
    var preferredDetentHeight: CGFloat {
        let rowHeight: CGFloat = 58
        let rowSpacing: CGFloat = 12
        let rowsTotal = options.isEmpty ? 0 : CGFloat(options.count) * rowHeight + CGFloat(options.count - 1) * rowSpacing
        let headerHeight: CGFloat = sheetSubtitle != nil ? 45 : 24
        // grabber(10+5) + gap(16) + header + gap(20) + rows + bottom(32)
        let contentHeight = 10 + 5 + 16 + headerHeight + 20 + rowsTotal + 32
        let maxHeight = UIScreen.main.bounds.height * 0.8
        return min(contentHeight, maxHeight)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupRows()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.backgroundColor = Theme.surface

        titleLabel.text = sheetTitle
        subtitleLabel.text = sheetSubtitle
        subtitleLabel.isHidden = sheetSubtitle == nil

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        view.addSubview(grabberView)
        view.addSubview(headerStack)
        view.addSubview(scrollView)
        scrollView.addSubview(rowStack)

        grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(5)
        }
        headerStack.snp.makeConstraints { make in
            make.top.equalTo(grabberView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
        rowStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 20, bottom: 32, right: 20))
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }
    }

    private func setupRows() {
        options.forEach { config in
            let row = OptionRow(config: config)
            row.snp.makeConstraints { make in make.height.equalTo(58) }
            row.tapPublisher
                .sink { [weak self] in
                    self?.dismiss(animated: true) { config.action() }
                }
                .store(in: &cancellables)
            rowStack.addArrangedSubview(row)
        }
    }
}

// MARK: - OptionRow

final class OptionRow: UIControl {

    // MARK: - UI

    private let iconBackground = UIView()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 16, weight: .semibold)
        return lb
    }()

    // MARK: - Publisher

    private let tapSubject = PassthroughSubject<Void, Never>()
    var tapPublisher: AnyPublisher<Void, Never> { tapSubject.eraseToAnyPublisher() }

    // MARK: - Init

    init(config: OptionRowConfig) {
        super.init(frame: .zero)

        let tintColor: UIColor = config.style == .destructive ? Theme.negative : Theme.textPrimary
        iconView.image = UIImage(systemName: config.icon)
        iconView.tintColor = tintColor
        titleLabel.text = config.title
        titleLabel.textColor = tintColor
        iconBackground.backgroundColor = tintColor.withAlphaComponent(0.1)

        setupLayout()

        backgroundColor = Theme.surface
        layer.cornerRadius = 16
        layer.masksToBounds = true
        addBorder(color: Theme.strokeSoft, borderWidth: 1)

        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        addBorder(color: Theme.strokeSoft, borderWidth: 1)
    }

    // MARK: - Layout

    private func setupLayout() {
        iconBackground.isUserInteractionEnabled = false
        iconBackground.layer.cornerRadius = 18

        addSubview(iconBackground)
        iconBackground.addSubview(iconView)
        addSubview(titleLabel)

        iconBackground.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalTo(iconBackground)
            make.width.height.equalTo(16)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackground.snp.trailing).offset(14)
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func handleTouchDown() { alpha = 0.6 }
    @objc private func handleTouchUp() { alpha = 1.0 }
    @objc private func handleTap() { tapSubject.send() }
}
