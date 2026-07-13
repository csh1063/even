//
//  TravelPeopleHeaderView.swift
//  Presentation
//
//  Created by sanghyeon on 7/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit

/// 여행 앨범 상세 상단에 전체 너비로 붙는 셀 — "A와 B와 사람 3명의 여행"처럼 등장 인물을 보여준다
final class TravelPeopleHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "TravelPeopleHeaderView"

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

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 15, weight: .semibold)
        lb.textColor = Theme.textPrimary
        lb.numberOfLines = 0
        return lb
    }()

    private static let outerMargin: CGFloat = 16
    private static let cardInnerPadding: CGFloat = 12
    private static let iconWidth: CGFloat = 18
    private static let iconTitleSpacing: CGFloat = 8

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(text: String) {
        titleLabel.text = text
    }

    static func height(for text: String, width: CGFloat) -> CGFloat {
        let cardWidth = width - outerMargin * 2
        let textWidth = cardWidth - cardInnerPadding * 2 - iconWidth - iconTitleSpacing

        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.numberOfLines = 0
        label.text = text
        let size = label.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude))

        return max(size.height, iconWidth) + cardInnerPadding * 2 + outerMargin
    }

    private func setupLayout() {
        addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)

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
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(Self.iconTitleSpacing)
            make.trailing.equalToSuperview().inset(Self.cardInnerPadding)
            make.top.equalToSuperview().offset(Self.cardInnerPadding)
            make.bottom.equalToSuperview().inset(Self.cardInnerPadding)
        }
    }
}
