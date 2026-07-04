//
//  LocationAlbumCell.swift
//  Presentation
//
//  Created by sanghyeon on 5/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

// MARK: - Style

enum AddressCellStyle {
    case large   // 그리드 전체 너비, 가로 레이아웃
    case small   // 절반 너비, 세로 레이아웃
}

final class LocationAlbumCell: UICollectionViewCell {

    // MARK: - UI

    private let containerView = UIView()

    // large 전용
    private let mapPreviewView = UIView()
    private let mapIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "map")?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = Theme.textTertiary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    // small 전용
    private let pinView  = UIView()
    private let pinIcon  = UIImageView()

    // 공통
    private let thumbImageView = UIImageView()
    private let placeLabel  = UILabel()
    private let subLabel    = UILabel()
    private let countLabel  = UILabel()

    private let badgeLabel  = UILabel()

    private var cellStyle: AddressCellStyle = .small

    private var task: Task<Void, Never>?
    private var assetIdentifier: String?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBase()
    }

    required init?(coder: NSCoder) {
        fatalError("LocationAlbumCell does not support NSCoding")
    }

    // MARK: - Setup

    private func setupBase() {
        contentView.backgroundColor = Theme.background

        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.layer.cornerRadius = 14
        thumbImageView.layer.masksToBounds = true
        contentView.addSubview(thumbImageView)
//        containerView.backgroundColor = Theme.surface.withAlphaComponent(0.6)
        containerView.backgroundColor = Theme.viewerBackground.withAlphaComponent(0.4)
        containerView.layer.cornerRadius = 14
        containerView.layer.masksToBounds = true
        containerView.addBorder(color: Theme.divider, borderWidth: 1)
        contentView.addSubview(containerView)

        thumbImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        thumbImageView.image = nil
        assetIdentifier = nil
    }

    // MARK: - Configure

    func configure(with viewModel: LocationAlbumCellViewModel, style: AddressCellStyle) {

        assetIdentifier = viewModel.localIdentifier
        // 재사용 시 이전 subview 제거
        containerView.subviews.forEach { $0.removeFromSuperview() }
        cellStyle = style

        placeLabel.text = viewModel.displayName
//        placeLabel.textColor = Theme.textPrimary
        placeLabel.textColor = .white// Theme.textPrimary
        placeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        placeLabel.numberOfLines = 1

        print("viewModel.displayName:", viewModel.displayName, ", viewModel.subText:", viewModel.subText)
        subLabel.text = viewModel.subText
//        subLabel.textColor = Theme.textSecondary
        subLabel.textColor = .white.withAlphaComponent(0.92) // Theme.textSecondary
        subLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subLabel.numberOfLines = 1

        countLabel.text = "사진 \(viewModel.photoCount.formatted())장"
//        countLabel.textColor = Theme.textTertiary
        countLabel.textColor = .white.withAlphaComponent(0.75) // Theme.textTertiary
        countLabel.font = .systemFont(ofSize: 11, weight: .regular)

        switch style {
        case .large:
            setupLarge(isMost: viewModel.isMost)
        case .small:
            setupSmall(pinColor: viewModel.pinColor)
        }

        task = Task {
            let size = CGSize(width: 88, height: 88)
            let image = await viewModel.loadImage(size: size)
            guard !Task.isCancelled, assetIdentifier == viewModel.localIdentifier else { return }
            thumbImageView.image = image
        }
    }

    // MARK: Large Layout

    private func setupLarge(isMost: Bool) {
        // 맵 미리보기 (컬러 박스)
        mapPreviewView.backgroundColor = Theme.secondary.withAlphaComponent(0.25)
        mapPreviewView.layer.cornerRadius = 10
        mapPreviewView.layer.masksToBounds = true
        containerView.addSubview(mapPreviewView)
        mapPreviewView.addSubview(mapIcon)

        containerView.addSubview(placeLabel)
        containerView.addSubview(subLabel)
        containerView.addSubview(countLabel)

//        if isMost {
//            badgeLabel.text = "최다"
//            badgeLabel.textColor = Theme.secondary
//            badgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
//            badgeLabel.backgroundColor = Theme.secondary.withAlphaComponent(0.85)
//            badgeLabel.layer.cornerRadius = 10
//            badgeLabel.layer.masksToBounds = true
//            badgeLabel.textAlignment = .center
//            containerView.addSubview(badgeLabel)
//
//            badgeLabel.snp.makeConstraints { make in
//                make.top.trailing.equalToSuperview().inset(10)
//                make.width.equalTo(36)
//                make.height.equalTo(20)
//            }
//        }

        mapPreviewView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(14)
            make.width.height.equalTo(60)
        }

        mapIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }

        placeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.leading.equalTo(mapPreviewView.snp.trailing).offset(14)
            make.trailing.equalToSuperview().inset(isMost ? 54 : 14)
        }

        subLabel.snp.makeConstraints { make in
            make.top.equalTo(placeLabel.snp.bottom).offset(4)
            make.leading.equalTo(placeLabel)
            make.trailing.equalToSuperview().inset(14)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(subLabel.snp.bottom).offset(6)
            make.leading.equalTo(placeLabel)
        }
    }

    // MARK: Small Layout

    private func setupSmall(pinColor: UIColor) {
        pinView.backgroundColor = pinColor
        pinView.layer.cornerRadius = 14
        pinView.layer.masksToBounds = true
        containerView.addSubview(pinView)

        pinIcon.image = UIImage(systemName: "mappin")?.withRenderingMode(.alwaysTemplate)
        pinIcon.tintColor = .white
        pinIcon.contentMode = .scaleAspectFit
        pinView.addSubview(pinIcon)

        containerView.addSubview(placeLabel)
        containerView.addSubview(subLabel)
        containerView.addSubview(countLabel)

        pinView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(28)
        }

        pinIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(14)
        }

        placeLabel.snp.makeConstraints { make in
            make.top.equalTo(pinView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        subLabel.snp.makeConstraints { make in
            make.top.equalTo(placeLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(subLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }
    }
}
