//
//  PhotoSectionHeaderView.swift
//  Presentation
//
//  Created by sanghyeon on 4/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

final class PhotoSectionHeaderView: UICollectionReusableView {
    
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func configure(with data: PhotoHeader) {
        titleLabel.text = data.title
        countLabel.text = "\(data.count)장"
    }
    
    private func setupView() {
        
        self.backgroundColor = Theme.background
        
        titleLabel.textColor = Theme.textPrimary
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        
        countLabel.textColor = Theme.textSecondary
        countLabel.font = .systemFont(ofSize: 14)
        countLabel.textAlignment = .right
        
        self.addSubview(titleLabel)
        self.addSubview(countLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(12)
            make.bottom.equalTo(self).offset(-12)
            make.leading.equalTo(self).inset(20)
        }
        
        countLabel.snp.makeConstraints { make in
            make.bottom.equalTo(titleLabel)
            make.trailing.equalTo(self).inset(20)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }
    }
}
