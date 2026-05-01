//
//  FolderCell.swift
//  Presentation
//
//  Created by sanghyeon on 3/23/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

final class FolderCell: UICollectionViewCell {
    
    private let radiusView: UIView = UIView()
    
    private let gradientView: GradientCardView = GradientCardView()
    private let mainImageView: UIImageView = UIImageView()
    private let imageIconView: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(systemName: "photo")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .white.withAlphaComponent(0.95)
        
        imageView.image = image
        
        return imageView
    }()
    
    private let contentsView: UIView = UIView()
    private let nameLabel: UILabel = UILabel()
    private let countLabel: UILabel = UILabel()
    private let descLabel: UILabel = UILabel()
    
    private var task: Task<Void, Never>?
    private var assetIdentifier: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        self.task?.cancel() // 로딩 중인 작업 즉시 중단
        self.mainImageView.image = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("PhotoCell does not support NSCoding")
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return layoutAttributes
    }
    
    func setupView() {
        
        self.contentView.backgroundColor = Theme.background
        
        self.radiusView.backgroundColor = Theme.surface
        self.radiusView.layer.cornerRadius = 20
        self.radiusView.layer.masksToBounds = true
        self.radiusView.addBorder(color: Theme.strokeSoft, borderWidth: 1)
        self.radiusView.addShadow(color: .black, opacity: 1, offset: CGSize(width: 0, height: 8), radius: 18)
        
        self.gradientView.layer.cornerRadius = 16
        self.gradientView.layer.masksToBounds = true
        self.gradientView.isHidden = true
        self.imageIconView.isHidden = true
        
        self.mainImageView.layer.cornerRadius = 16
        self.mainImageView.layer.masksToBounds = true
        self.mainImageView.backgroundColor = .clear
        self.mainImageView.contentMode = .scaleAspectFill
        
        self.contentsView.backgroundColor = Theme.surfaceWarm
        
        self.nameLabel.textColor = Theme.textPrimary
        self.nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        self.nameLabel.numberOfLines = 2
        
        self.countLabel.textColor = Theme.textPrimary
        self.countLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        
        self.descLabel.textColor = Theme.textSecondary
        self.descLabel.font = .systemFont(ofSize: 13, weight: .regular)
        
        self.contentView.addSubview(radiusView)
        
        self.radiusView.addSubview(gradientView)
        self.radiusView.addSubview(imageIconView)
        self.radiusView.addSubview(mainImageView)
        self.radiusView.addSubview(contentsView)
        self.contentsView.addSubview(nameLabel)
        self.contentsView.addSubview(countLabel)
        self.contentsView.addSubview(descLabel)
        
        self.radiusView.snp.makeConstraints { make in
            make.edges.equalTo(self.contentView)
        }
        
        self.gradientView.snp.makeConstraints { make in
            make.edges.equalTo(self.mainImageView).inset(-1)
        }
        
        self.imageIconView.snp.makeConstraints { make in
            make.leading.bottom.equalTo(gradientView).inset(12)
        }
        
        self.mainImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.radiusView).inset(12)
            make.height.equalTo(self.mainImageView.snp.width).multipliedBy(4.0/5.0)
//            make.height.equalTo(136)
        }
        
        self.contentsView.snp.makeConstraints { make in
            make.top.equalTo(self.mainImageView.snp.bottom).offset(10)
            make.bottom.leading.trailing.equalTo(self.radiusView)
        }
        
        self.nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self.contentsView).inset(12)
            make.leading.trailing.equalTo(self.contentsView).inset(12)
        }
        
        self.countLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentsView).inset(12)
            make.top.equalTo(self.nameLabel.snp.bottom).offset(6)
        }
        
        self.descLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.nameLabel)
            make.top.equalTo(self.countLabel.snp.bottom).offset(6)
            make.bottom.equalTo(self.contentsView).inset(12)
        }
    }
    
    func configure(with viewModel: FolderCellItemViewModel, index: Int) {
        self.assetIdentifier = viewModel.localIdentifier
        
        self.gradientView.colors = [
            Theme.accent,
            Theme.primary,
            Theme.secondary
        ].map {$0.withAlphaComponent(0.5)}
        self.gradientView.isHidden = false
        self.imageIconView.isHidden = false
        
        self.nameLabel.text = viewModel.folder.displayName
        self.countLabel.text = "\(viewModel.folder.photoCount.formatted())장"
        self.descLabel.text = "설명설명"
        
        task = Task {
            let size = self.frame.size
            let image = await viewModel.loadImage(size: CGSize(
                width: size.width * 2,
                height: size.height * 2
            ))
            
            if !Task.isCancelled && self.assetIdentifier == viewModel.localIdentifier {
                self.mainImageView.image = image
                
//                self.gradientView.colors = [
//                    Theme.accent,
//                    Theme.primary,
//                    Theme.secondary
//                ].map {$0.withAlphaComponent(0.5)}
                
            }
//            self.gradientView.isHidden = true
            self.imageIconView.isHidden = true
        }
    }
}
