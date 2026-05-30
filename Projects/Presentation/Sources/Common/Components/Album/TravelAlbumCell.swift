//
//  TravelAlbumCell.swift
//  Presentation
//
//  Created by sanghyeon on 5/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

final class TravelAlbumCell: UICollectionViewCell {

    // MARK: - UI

    private let containerView = UIView()

    private let thumbImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Theme.strokeSoft
        return iv
    }()

    private let thumbOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.accent.withAlphaComponent(0.15)
        return v
    }()

    private let placeholderIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "airplane")?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = Theme.textTertiary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let infoView = UIView()

    private let badgeView  = UIView()
    private let badgeIcon  = UIImageView()
    private let badgeLabel = UILabel()

    private let nameLabel  = UILabel()
    private let dateLabel  = UILabel()
    private let countLabel = UILabel()

    private var task: Task<Void, Never>?
    private var assetIdentifier: String?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("TravelAlbumCell does not support NSCoding")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        thumbImageView.image = nil
        placeholderIcon.isHidden = false
        assetIdentifier = nil
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = Theme.background

        containerView.backgroundColor = Theme.surfaceWarm
        containerView.layer.cornerRadius = 18
        containerView.layer.masksToBounds = true
        containerView.addBorder(color: Theme.strokeSoft, borderWidth: 1)
        contentView.addSubview(containerView)

        // 썸네일 (고정 너비)
        containerView.addSubview(thumbImageView)
        thumbImageView.addSubview(thumbOverlay)
        thumbImageView.addSubview(placeholderIcon)

        // 정보 영역
        infoView.backgroundColor = .clear
        containerView.addSubview(infoView)

        // 배지
        badgeView.backgroundColor = Theme.accent
        badgeView.layer.cornerRadius = 6
        badgeView.layer.masksToBounds = true
        infoView.addSubview(badgeView)

        badgeIcon.image = UIImage(systemName: "mappin.and.ellipse")?.withRenderingMode(.alwaysTemplate)
        badgeIcon.tintColor = UIColor("#7a4a00")
        badgeIcon.contentMode = .scaleAspectFit
        badgeView.addSubview(badgeIcon)

        badgeLabel.textColor = UIColor("#7a4a00")
        badgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        badgeView.addSubview(badgeLabel)

        nameLabel.textColor = Theme.textPrimary
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.numberOfLines = 1
        infoView.addSubview(nameLabel)

        dateLabel.textColor = Theme.textSecondary
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        infoView.addSubview(dateLabel)

        countLabel.textColor = Theme.textTertiary
        countLabel.font = .systemFont(ofSize: 12, weight: .regular)
        infoView.addSubview(countLabel)

        // MARK: Constraints

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        thumbImageView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(100)
        }

        thumbOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        placeholderIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(32)
        }

        infoView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.leading.equalTo(thumbImageView.snp.trailing)
            make.height.equalTo(100)
        }

        badgeView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.leading.equalToSuperview().inset(14)
            make.height.equalTo(20)
        }

        badgeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(7)
            make.centerY.equalToSuperview()
            make.size.equalTo(11)
        }

        badgeLabel.snp.makeConstraints { make in
            make.leading.equalTo(badgeIcon.snp.trailing).offset(3)
            make.trailing.equalToSuperview().inset(7)
            make.centerY.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(badgeView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(14)
        }
    }

    // MARK: - Configure

    func configure(with viewModel: TravelAlbumCellViewModel) {
        assetIdentifier = viewModel.localIdentifier
        badgeLabel.text = viewModel.countryName
        nameLabel.text  = viewModel.displayName
        dateLabel.text  = viewModel.dateRangeText
        countLabel.text = "사진 \(viewModel.photoCount.formatted())장"

        task = Task {
            let size = CGSize(width: 200, height: 200)
            let image = await viewModel.loadImage(size: size)
            guard !Task.isCancelled, assetIdentifier == viewModel.localIdentifier else { return }
            thumbImageView.image = image
            placeholderIcon.isHidden = true
        }
    }
}
