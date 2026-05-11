//
//  OpenSourceCell.swift
//  Presentation
//
//  Created by sanghyeon on 5/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Combine

final class OpenSourceCell: UITableViewCell {

    static let reuseIdentifier = "OpenSourceCell"

    var onURLTapped: ((String) -> Void)?

    // MARK: - UI
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Theme.textPrimary
        return label
    }()

    private let urlButtonCoverView = UIView()
    private let urlButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setTitleColor(Theme.secondary, for: .normal) // warm sand
        button.contentHorizontalAlignment = .left
        return button
    }()

    private let copyrightLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = Theme.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let licenseToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.setTitleColor(Theme.secondary, for: .normal)
        button.contentHorizontalAlignment = .left
        return button
    }()

    private let licenseTextView: UITextView = {
        let tv = UITextView()
        tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.textColor = Theme.textSecondary
        tv.backgroundColor = Theme.surface
        tv.layer.cornerRadius = 6
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        tv.isHidden = true
        return tv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 4
        return sv
    }()
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = UIColor(named: "Cream") ?? .systemBackground
        selectionStyle = .none

        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(urlButtonCoverView)
        urlButtonCoverView.addSubview(urlButton)
        stackView.addArrangedSubview(copyrightLabel)
        stackView.addArrangedSubview(licenseToggleButton)
        stackView.addArrangedSubview(licenseTextView)
        stackView.setCustomSpacing(2, after: nameLabel)
        stackView.setCustomSpacing(2, after: urlButton)
        stackView.setCustomSpacing(6, after: copyrightLabel)
        stackView.setCustomSpacing(8, after: licenseToggleButton)

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.bottom.equalToSuperview().offset(-14)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        urlButton.snp.makeConstraints { make in
            make.top.bottom.leading.equalTo(urlButtonCoverView)
        }
    }
    
    private func bind() {
        urlButton.publisher(for: .touchUpInside)
            .sink { button in
                guard let url = button.title(for: .normal) else { return }
                self.onURLTapped?(url)
            }
            .store(in: &cancellables)
    }

    func configure(with license: OpenSourceLicense, isExpanded: Bool) {
        nameLabel.text = license.name
        urlButton.setTitle(license.url, for: .normal)
        copyrightLabel.text = license.copyright

        let arrow = isExpanded ? "▼" : "▶"
        licenseToggleButton.setTitle("\(arrow) \(license.licenseType)", for: .normal)

        licenseTextView.text = license.licenseText
        licenseTextView.isHidden = !isExpanded
    }
}
