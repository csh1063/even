//
//  SimilarAlbumCell.swift
//  Presentation
//
//  Created by sanghyeon on 6/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain
final class SimilarAlbumCell: UICollectionViewCell {

    // MARK: - UI

    private let stackContainer = UIView()

    private let backImageView   = makeImageView()
    private let midImageView    = makeImageView()
    private let frontImageView  = makeImageView()

    private let countBadge = UILabel()
//    private let nameLabel  = UILabel()

    private var task: Task<Void, Never>?
    private var currentIdentifier: String?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("SimilarAlbumCell does not support NSCoding")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        frontImageView.image = nil
        midImageView.image   = nil
        backImageView.image  = nil
        currentIdentifier = nil
    }

    // MARK: - Setup

    private func setupView() {
        contentView.backgroundColor = Theme.background

        // 스택 컨테이너 — back → mid → front 순으로 추가
        contentView.addSubview(stackContainer)
        stackContainer.addSubview(backImageView)
        stackContainer.addSubview(midImageView)
        stackContainer.addSubview(frontImageView)

        // rotation
        backImageView.transform  = CGAffineTransform(rotationAngle: .pi / 30)   //  6도
        midImageView.transform   = CGAffineTransform(rotationAngle: .pi / 60)   //  3도
        frontImageView.transform = .identity

        countBadge.backgroundColor = Theme.primary
        countBadge.textColor       = .white
        countBadge.font            = .systemFont(ofSize: 10, weight: .bold)
        countBadge.textAlignment   = .center
        countBadge.layer.cornerRadius  = 8
        countBadge.layer.masksToBounds = true
        countBadge.layer.borderWidth   = 1.5
        countBadge.layer.borderColor   = Theme.background.cgColor
        contentView.addSubview(countBadge)

//        nameLabel.textAlignment  = .center
//        nameLabel.numberOfLines  = 1
//        nameLabel.textColor      = Theme.textSecondary
//        nameLabel.font           = .systemFont(ofSize: 12, weight: .regular)
//        nameLabel.text           = "유사한 사진"
//        contentView.addSubview(nameLabel)

        let size: CGFloat = 64

        stackContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(72)
        }

        // front: 좌하단 기준, back/mid는 살짝 오른쪽으로 offset
        frontImageView.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview()
            make.width.height.equalTo(size)
        }
        midImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-2)
            make.width.height.equalTo(size)
        }
        backImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-4)
            make.width.height.equalTo(size)
        }

        countBadge.snp.makeConstraints { make in
            make.bottom.equalTo(stackContainer)
            make.trailing.equalTo(stackContainer).offset(2)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(24)
        }

//        nameLabel.snp.makeConstraints { make in
//            make.top.equalTo(stackContainer.snp.bottom).offset(6)
//            make.leading.trailing.bottom.equalToSuperview()
//        }
    }

    // MARK: - Configure

    func configure(with viewModel: SimilarAlbumCellViewModel, hasCover: Bool = false) {
        currentIdentifier    = viewModel.localIdentifier
        countBadge.text      = "×\(viewModel.photoCount)"

        let isTwoPhotos = viewModel.photoCount == 2
        backImageView.isHidden = isTwoPhotos

//        if hasCover {
//            contentView.addShadow(color: .black, opacity: 0.3, offset: CGSize(width: 4, height: 4), radius: 8)
//        }

        task = Task {
            let image = await viewModel.loadImage(size: CGSize(width: 128, height: 128))
            guard !Task.isCancelled, currentIdentifier == viewModel.localIdentifier else { return }

            frontImageView.image = image
            midImageView.image   = image
            backImageView.image  = image
        }
    }

    // MARK: - Factory

    private static func makeImageView() -> UIImageView {
        let iv = UIImageView()
        iv.contentMode    = .scaleAspectFill
        iv.clipsToBounds  = true
        iv.backgroundColor = Theme.strokeSoft
        iv.layer.cornerRadius = 10
        iv.layer.borderWidth  = 0.5
        iv.layer.borderColor  = UIColor.white.withAlphaComponent(0.6).cgColor
        return iv
    }
}
