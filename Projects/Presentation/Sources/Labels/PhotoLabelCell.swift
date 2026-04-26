//
//  PhotoLabelCell.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

final class PhotoLabelCell: UICollectionViewCell {
    
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("PhotoLabelCell does not support NSCoding.")
    }
    
    private func setupView() {
        
        contentView.layer.cornerRadius = 16
        contentView.backgroundColor = Theme.primary.withAlphaComponent(0.2)
        
        label.textColor = Theme.textPrimary
        
        contentView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }
    }
    
    // ✅ 이게 핵심 — 셀 너비가 화면을 넘지 않도록
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(
            width: UIScreen.main.bounds.width - 32,  // sectionInset 양쪽 합산
            height: UIView.layoutFittingCompressedSize.height
        )
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )
        return layoutAttributes
    }
    
    func configure(with photoLabel: String) {
        label.text = photoLabel
    }
}
