//
//  AlbumSectionHeaderView.swift
//  Presentation
//
//  Created by sanghyeon on 5/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit
import SnapKit

final class AlbumSectionHeaderView: UICollectionReusableView {

    // MARK: - UI

    private let titleLabel = UILabel()
    let moreButton = UIButton(type: .system)

    var onMoreTapped: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("AlbumSectionHeaderView does not support NSCoding")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear

        titleLabel.textColor = Theme.textPrimary
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        addSubview(titleLabel)

        moreButton.setTitle("모두 보기", for: .normal)
        moreButton.setTitleColor(Theme.primary, for: .normal)
        moreButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        addSubview(moreButton)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    @objc private func moreTapped() {
        onMoreTapped?()
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}