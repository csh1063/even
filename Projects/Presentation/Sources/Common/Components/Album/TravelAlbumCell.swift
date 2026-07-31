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

    private let placeholderIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "airplane")?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = Theme.textTertiary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // 사진 위에 텍스트가 읽히도록 하단만 어둡게 깔아주는 그라데이션 (공용 GradientView 재사용)
    private let gradientView = GradientView()

    private let nameLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.font = .systemFont(ofSize: 17, weight: .bold)
        lb.numberOfLines = 1
        return lb
    }()

    private let dateLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = UIColor.white.withAlphaComponent(0.85)
        lb.font = .systemFont(ofSize: 13, weight: .regular)
        return lb
    }()

    private let countLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = UIColor.white.withAlphaComponent(0.85)
        lb.font = .systemFont(ofSize: 13, weight: .regular)
        lb.textAlignment = .right
        return lb
    }()

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
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        containerView.addBorder(color: Theme.strokeSoft, borderWidth: 1)
        contentView.addSubview(containerView)

        containerView.addSubview(thumbImageView)
        thumbImageView.addSubview(placeholderIcon)
        containerView.addSubview(gradientView)

        gradientView.addSubview(nameLabel)
        gradientView.addSubview(dateLabel)
        gradientView.addSubview(countLabel)

        // MARK: Constraints

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        thumbImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        placeholderIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(36)
        }

        gradientView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.6)
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(dateLabel.snp.top).offset(-2)
        }

        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(14)
        }

        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(dateLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(dateLabel)
        }
    }

    // MARK: - Configure

    func configure(with viewModel: TravelAlbumCellViewModel) {
        assetIdentifier = viewModel.localIdentifier
        nameLabel.text = viewModel.displayName
        dateLabel.text = viewModel.dateRangeText
        countLabel.text = String(localized: "\(viewModel.photoCount.formatted())장", bundle: .module)

        task = Task {
            let size = CGSize(width: 400, height: 400)
            let image = await viewModel.loadImage(size: size)
            guard !Task.isCancelled, assetIdentifier == viewModel.localIdentifier else { return }
            thumbImageView.image = image
            placeholderIcon.isHidden = image != nil
        }
    }
}
