//
//  CategoryAlbumCell.swift
//  Presentation
//
//  Created by sanghyeon on 5/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

final class CategoryAlbumCell: UICollectionViewCell {

    // MARK: - UI

    private let containerView = UIView()
    private let separatorView = UIView()

    private let iconWrapView = UIView()
    private let iconView     = UIImageView()

    private let nameLabel  = UILabel()
    private let countLabel = UILabel()

    private let thumbImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Theme.divider
        return iv
    }()

    private let chevronIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = Theme.textTertiary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private var task: Task<Void, Never>?
    private var assetIdentifier: String?

    // 상단/하단 코너 라운드 제어용
    var isFirst: Bool = false { didSet { updateCorners() } }
    var isLast: Bool  = false { didSet { updateCorners() } }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("CategoryAlbumCell does not support NSCoding")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        thumbImageView.image = nil
        assetIdentifier = nil
        isFirst = false
        isLast  = false
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = Theme.background

        containerView.backgroundColor = Theme.surface
        contentView.addSubview(containerView)

        separatorView.backgroundColor = Theme.strokeSoft
        containerView.addSubview(separatorView)

        iconWrapView.layer.cornerRadius = 9
        iconWrapView.layer.masksToBounds = true
        containerView.addSubview(iconWrapView)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconWrapView.addSubview(iconView)

        nameLabel.textColor = Theme.textPrimary
        nameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        containerView.addSubview(nameLabel)

        countLabel.textColor = Theme.textSecondary
        countLabel.font = .systemFont(ofSize: 12, weight: .regular)
        containerView.addSubview(countLabel)

        thumbImageView.layer.cornerRadius = 8
        containerView.addSubview(thumbImageView)

        containerView.addSubview(chevronIcon)

        // MARK: Constraints

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconWrapView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconWrapView.snp.trailing).offset(14)
            make.top.equalToSuperview().inset(12)
            make.trailing.equalTo(thumbImageView.snp.leading).offset(-12)
        }

        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(3)
            make.bottom.equalToSuperview().inset(12)
        }

        chevronIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(14)
        }

        thumbImageView.snp.makeConstraints { make in
            make.trailing.equalTo(chevronIcon.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }

        separatorView.snp.makeConstraints { make in
            make.leading.equalTo(iconWrapView.snp.trailing).offset(14)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    private func updateCorners() {
        var corners: CACornerMask = []
        if isFirst {
            corners.insert(.layerMinXMinYCorner)
            corners.insert(.layerMaxXMinYCorner)
        }
        if isLast {
            corners.insert(.layerMinXMaxYCorner)
            corners.insert(.layerMaxXMaxYCorner)
            separatorView.isHidden = true
        } else {
            separatorView.isHidden = false
        }
        containerView.layer.cornerRadius = (isFirst || isLast) ? 14 : 0
        containerView.layer.maskedCorners = corners
        containerView.layer.masksToBounds = true
    }

    // MARK: - Configure

    func configure(with viewModel: CategoryAlbumCellViewModel) {
        assetIdentifier = viewModel.localIdentifier

        iconView.image = UIImage(systemName: viewModel.systemIconName)?.withRenderingMode(.alwaysTemplate)
        iconWrapView.backgroundColor = viewModel.iconColor
        nameLabel.text  = viewModel.displayName
        countLabel.text = String(localized: "사진 \(viewModel.photoCount.formatted())장", bundle: .module)

        task = Task {
            let size = CGSize(width: 88, height: 88)
            let image = await viewModel.loadImage(size: size)
            guard !Task.isCancelled, assetIdentifier == viewModel.localIdentifier else { return }
            thumbImageView.image = image
        }
    }
}
