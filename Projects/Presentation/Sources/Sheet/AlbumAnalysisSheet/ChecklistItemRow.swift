//
//  ChecklistItemRow.swift
//  Presentation
//
//  Created by sanghyeon on 9/1/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

/// "자세히" 목록 한 줄 — 아이콘 + 이름 + 상태(대기 · 진행중 · 완료). 정확한 진행률(%) 대신 세
/// 상태만 표시한다 — 대부분의 항목이 순간적으로 끝나는 작업이라 매끄러운 %보다 "지금 뭐가 끝났고
/// 다음이 뭔지"를 보여주는 체크리스트가 더 정직하다.
final class ChecklistItemRow: UIView {

    enum State {
        case waiting
        case inProgress
        case done
    }

    private let iconBackground: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surfaceCool
        view.layer.cornerRadius = 13
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Theme.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13.5, weight: .medium)
        label.textColor = Theme.textPrimary
        return label
    }()

    private let spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = Theme.primary
        view.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        return view
    }()

    private let checkIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        let imageView = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: config))
        imageView.tintColor = Theme.positive
        return imageView
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11.5, weight: .semibold)
        return label
    }()

    private let statusStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private var state: State = .waiting

    init(icon: String, title: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        setupLayout()
        apply(state: .waiting)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setState(_ newState: State) {
        guard newState != state else { return }
        state = newState
        apply(state: newState)
    }

    private func apply(state: State) {
        switch state {
        case .waiting:
            spinner.stopAnimating()
            checkIcon.isHidden = true
            iconView.tintColor = Theme.textTertiary
            titleLabel.textColor = Theme.textTertiary
            statusLabel.text = String(localized: "대기", bundle: .module)
            statusLabel.textColor = Theme.textTertiary
        case .inProgress:
            spinner.startAnimating()
            checkIcon.isHidden = true
            iconView.tintColor = Theme.primary
            titleLabel.textColor = Theme.textPrimary
            statusLabel.text = String(localized: "진행중", bundle: .module)
            statusLabel.textColor = Theme.primary
        case .done:
            spinner.stopAnimating()
            checkIcon.isHidden = false
            iconView.tintColor = Theme.positive
            titleLabel.textColor = Theme.textPrimary
            statusLabel.text = String(localized: "완료", bundle: .module)
            statusLabel.textColor = Theme.positive
        }
    }

    private func setupLayout() {
        iconBackground.addSubview(iconView)
        addSubview(iconBackground)
        addSubview(titleLabel)

        statusStack.addArrangedSubview(spinner)
        statusStack.addArrangedSubview(checkIcon)
        addSubview(statusStack)
        addSubview(statusLabel)

        self.snp.makeConstraints { make in
            make.height.equalTo(34)
        }

        iconBackground.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.centerY.equalTo(self)
            make.width.height.equalTo(26)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalTo(iconBackground)
            make.width.height.equalTo(13)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackground.snp.trailing).offset(10)
            make.centerY.equalTo(self)
        }

        checkIcon.snp.makeConstraints { make in
            make.width.height.equalTo(9)
        }

        statusStack.snp.makeConstraints { make in
            make.trailing.equalTo(statusLabel.snp.leading).offset(-5)
            make.centerY.equalTo(self)
        }

        statusLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self)
            make.centerY.equalTo(self)
        }
    }
}
