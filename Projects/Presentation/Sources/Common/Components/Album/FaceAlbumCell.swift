//
//  FaceAlbumCell.swift
//  Presentation
//
//  Created by sanghyeon on 5/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

final class FaceAlbumCell: UICollectionViewCell {

    // MARK: - UI

    private let avatarContainer = UIView()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Theme.strokeSoft
        return iv
    }()

    private let placeholderIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.fill")?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = Theme.textTertiary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let countBadge = UILabel()
    private let nameLabel  = UILabel()

    private var task: Task<Void, Never>?
    private var currentIdentifier: String?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("FaceAlbumCell does not support NSCoding")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        avatarImageView.image = nil
        placeholderIcon.isHidden = false
        avatarContainer.layer.borderColor = Theme.strokeSoft.cgColor
        avatarContainer.layer.borderWidth = 2.5
        currentIdentifier = nil
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = Theme.background

        avatarContainer.layer.cornerRadius = 34
        avatarContainer.layer.masksToBounds = true
        avatarContainer.layer.borderWidth = 2.5
        avatarContainer.layer.borderColor = Theme.strokeSoft.cgColor
        contentView.addSubview(avatarContainer)

        avatarImageView.layer.cornerRadius = 34
        avatarContainer.addSubview(avatarImageView)
        avatarContainer.addSubview(placeholderIcon)

        countBadge.backgroundColor = Theme.primary
        countBadge.textColor = .white
        countBadge.font = .systemFont(ofSize: 10, weight: .bold)
        countBadge.textAlignment = .center
        countBadge.layer.cornerRadius = 8
        countBadge.layer.masksToBounds = true
        countBadge.layer.borderWidth = 1.5
        countBadge.layer.borderColor = Theme.background.cgColor
        contentView.addSubview(countBadge)

        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        contentView.addSubview(nameLabel)

        avatarContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(68)
        }
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.height.equalTo(68)
        }
        placeholderIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(30)
        }
        countBadge.snp.makeConstraints { make in
            make.bottom.equalTo(avatarContainer)
            make.trailing.equalTo(avatarContainer).offset(2)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(24)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarContainer.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Configure

    func configure(with viewModel: FaceCellViewModel) {
        currentIdentifier = viewModel.localIdentifier
        countBadge.text   = "\(viewModel.photoCount)"

        if viewModel.isNamed {
            nameLabel.text      = viewModel.displayName
            nameLabel.textColor = Theme.textSecondary
            nameLabel.font      = .systemFont(ofSize: 12, weight: .regular)
        } else {
            nameLabel.text      = "미확인"
            nameLabel.textColor = Theme.textTertiary
            nameLabel.font      = .italicSystemFont(ofSize: 12)
        }

        avatarContainer.layer.borderColor = viewModel.isHighlighted
            ? Theme.primary.cgColor
            : Theme.strokeSoft.cgColor

        task = Task {
            let image = await viewModel.loadImage(size: CGSize(width: 136, height: 136))
            guard !Task.isCancelled, currentIdentifier == viewModel.localIdentifier else { return }
            avatarImageView.image = image
            placeholderIcon.isHidden = image != nil
        }
    }
}
