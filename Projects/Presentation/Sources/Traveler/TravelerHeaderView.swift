//
//  TravelerHeaderView.swift
//  Presentation
//
//  Created by sanghyeon on 7/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit

/// 여행 앨범 상세 상단에 전체 너비로 붙는 셀 — "A와 B와 사람 3명의 여행"처럼 등장 인물을 보여준다
final class TravelerHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "TravelerHeaderView"

    // 화면 가장자리에 카드가 딱 붙지 않도록 바깥쪽 여백을 두는 컨테이너
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.surfaceWarm
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.2.fill")
        iv.tintColor = Theme.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 15, weight: .semibold)
        lb.textColor = Theme.textPrimary
        lb.numberOfLines = 0
        return lb
    }()

    private let countLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 13, weight: .medium)
        lb.textColor = Theme.textSecondary
        return lb
    }()

    private static let outerMargin: CGFloat = 16
    private static let cardInnerPadding: CGFloat = 12
    private static let iconWidth: CGFloat = 18
    private static let iconTitleSpacing: CGFloat = 8
    // count 라벨("N명")이 대략 차지하는 폭 — height 계산 시 nameLabel이 줄바꿈될 지점을 대략 맞추기 위한 여유값
    private static let countLabelReservedWidth: CGFloat = 44

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, count: Int) {
        nameLabel.text = name
        countLabel.text = String(localized: "\(count)명", bundle: .module)
    }

    static func height(for name: String, width: CGFloat) -> CGFloat {
        let cardWidth = width - outerMargin * 2
        let textWidth = cardWidth - cardInnerPadding * 2 - iconWidth - iconTitleSpacing - countLabelReservedWidth

        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.numberOfLines = 0
        label.text = name
        let size = label.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude))

        return max(size.height, iconWidth) + cardInnerPadding * 2 + outerMargin
    }

    private func setupLayout() {
        addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(countLabel)

        cardView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Self.outerMargin)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(Self.outerMargin)
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Self.cardInnerPadding)
            make.top.equalToSuperview().offset(Self.cardInnerPadding)
            make.width.height.equalTo(Self.iconWidth)
        }
        countLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Self.cardInnerPadding)
            make.centerY.equalTo(iconView)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(Self.iconTitleSpacing)
            make.trailing.equalTo(countLabel.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(Self.cardInnerPadding)
            make.bottom.equalToSuperview().inset(Self.cardInnerPadding)
        }
    }
}
