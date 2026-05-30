//
//  DateAlbumCell.swift
//  Presentation
//
//  Created by sanghyeon on 5/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit
import SnapKit
import Domain

final class DateAlbumCell: UICollectionViewCell {

    // MARK: - UI

    private let containerView = UIView()

    /// 콜라주: 상단 wide 1장 + 하단 2장
    private let topPhotoView            = UIImageView()
//    private let bottomLeadingPhotoView  = UIImageView()
//    private let bottomTrailingPhotoView = UIImageView()

    private let placeholderIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "photo.on.rectangle")?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = Theme.textTertiary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let overlayView = UIView()
    private let yearLabel   = UILabel()
    private let countLabel  = UILabel()

    private var tasks: [Task<Void, Never>] = []
    private var currentIdentifier: String?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("DateAlbumCell does not support NSCoding")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tasks.forEach { $0.cancel() }
        tasks = []
        currentIdentifier = nil
        topPhotoView.image = nil
//        bottomLeadingPhotoView.image = nil
//        bottomTrailingPhotoView.image = nil
        placeholderIcon.isHidden = false
    }
    
    override func layoutSubviews() {
//            super.layoutSubviews()
            // Cell의 최종 bounds 크기를 레이어에 주입
//        self.layoutIfNeeded()
            
            super.layoutSubviews()
        overlayView.layoutIfNeeded()
        if let gradient = overlayView.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = overlayView.bounds
        }
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = Theme.background

        containerView.backgroundColor = Theme.surface
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        containerView.addBorder(color: Theme.strokeSoft, borderWidth: 1)
        contentView.addSubview(containerView)

        [topPhotoView/*, bottomLeadingPhotoView, bottomTrailingPhotoView*/].forEach {
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
            $0.backgroundColor = Theme.strokeSoft
            containerView.addSubview($0)
        }

        containerView.addSubview(placeholderIcon)

        overlayView.backgroundColor = .clear
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        gradient.locations = [0.4, 1.0]
        overlayView.layer.addSublayer(gradient)
        containerView.addSubview(overlayView)

        yearLabel.textColor = .white
        yearLabel.font = .systemFont(ofSize: 22, weight: .bold)
        containerView.addSubview(yearLabel)

        countLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        countLabel.font = .systemFont(ofSize: 12, weight: .regular)
        containerView.addSubview(countLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        topPhotoView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
//            make.height.equalToSuperview().multipliedBy(0.6)
            make.bottom.equalToSuperview()
        }
//        bottomLeadingPhotoView.snp.makeConstraints { make in
//            make.top.equalTo(topPhotoView.snp.bottom).offset(2)
//            make.leading.bottom.equalToSuperview()
//            make.trailing.equalTo(containerView.snp.centerX).offset(-1)
//        }
//        bottomTrailingPhotoView.snp.makeConstraints { make in
//            make.top.equalTo(topPhotoView.snp.bottom).offset(2)
//            make.trailing.bottom.equalToSuperview()
//            make.leading.equalTo(containerView.snp.centerX).offset(1)
//        }
        placeholderIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(36)
        }
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        countLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }
        yearLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(countLabel.snp.top).offset(-2)
        }
    }
    
    // MARK: - Configure

    func configure(with viewModel: DateAlbumCellViewModel) {

        currentIdentifier = viewModel.localIdentifier
        yearLabel.text  = viewModel.displayName
        countLabel.text = "사진 \(viewModel.photoCount.formatted())장"

        // 커버 1장을 3분할 위치 모두에 동일하게 사용
        // 실제로 여러 장 커버가 생기면 photos 배열에서 추가 identifier 받아 확장
        let photoViews = [topPhotoView/*, bottomLeadingPhotoView, bottomTrailingPhotoView*/]
        photoViews.forEach { $0.image = nil }

        let t = Task {
            let size = CGSize(width: 300, height: 300)
            let image = await viewModel.loadImage(size: size)
            guard !Task.isCancelled, currentIdentifier == viewModel.localIdentifier else { return }
            photoViews.forEach { $0.image = image }
            placeholderIcon.isHidden = image != nil
        }
        tasks.append(t)
    }
}
