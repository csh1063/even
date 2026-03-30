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
    private let mainImageView: UIImageView = UIImageView()
    private let textCoverView: UIView = UIView()
    private let nameLabel: UILabel = UILabel()
    private let countLabel: UILabel = UILabel()
    
    private let loadingView: UIView = UIView()
    
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
    
    func setupView() {
        
        self.contentView.backgroundColor = .Theme.white
        
        self.textCoverView.backgroundColor = .Theme.obsidian.withAlphaComponent(0.5)
        
        self.radiusView.layer.cornerRadius = 12
        self.radiusView.layer.masksToBounds = true
        
        self.mainImageView.backgroundColor = .Theme.obsidian
        self.mainImageView.contentMode = .scaleAspectFill
        
        self.nameLabel.textColor = .Theme.frost
        self.nameLabel.font = .systemFont(ofSize: 16)
        self.nameLabel.numberOfLines = 2
        self.countLabel.textColor = .Theme.frost
        self.countLabel.font = .systemFont(ofSize: 16)
        
        self.contentView.addSubview(radiusView)
        self.radiusView.addSubview(mainImageView)
        self.radiusView.addSubview(textCoverView)
        self.radiusView.addSubview(nameLabel)
        self.radiusView.addSubview(countLabel)
        self.contentView.addSubview(loadingView)
        
        self.radiusView.snp.makeConstraints { make in
            make.edges.equalTo(self.contentView).inset(4)
        }
        
        self.mainImageView.snp.makeConstraints { make in
            make.edges.equalTo(self.radiusView)
        }
        
        self.textCoverView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(mainImageView)
            make.top.equalTo(self.nameLabel).offset(-8)
        }
        
        self.nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.mainImageView).offset(8)
            make.trailing.equalTo(self.countLabel.snp.leading).offset(-12)
            make.bottom.equalTo(self.mainImageView).offset(-8)
        }
        
        self.countLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.mainImageView).offset(-8)
            make.bottom.equalTo(self.mainImageView).offset(-8)
        }
        
        self.loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.center.equalTo(self.contentView)
        }
    }
    
    func configure(with viewModel: FolderCellItemViewModel) {
        self.assetIdentifier = viewModel.localIdentifier
        self.loadingView.isHidden = false
        
        self.nameLabel.text = viewModel.folder.displayName
        self.countLabel.text = "\(viewModel.folder.photoCount)"
        
        task = Task {
            let size = self.frame.size
            let image = await viewModel.loadImage(size: CGSize(
                width: size.width * 2,
                height: size.height * 2
            ))
            
            if !Task.isCancelled && self.assetIdentifier == viewModel.localIdentifier {
                self.mainImageView.image = image
            }
            self.loadingView.isHidden = true
        }
    }
}
