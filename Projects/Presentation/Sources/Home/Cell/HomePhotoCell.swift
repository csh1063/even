//
//  HomePhotoCell.swift
//  Presentation
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

final class HomePhotoCell: UICollectionViewCell {
    
    private let mainImageView: UIImageView = UIImageView()
    
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
        fatalError("HomePhotoCell does not support NSCoding")
    }
    
    func setupView() {
        
        self.contentView.backgroundColor = .Theme.obsidian
        
        self.mainImageView.layer.masksToBounds = true
        self.mainImageView.contentMode = .scaleAspectFill
        
        self.loadingView.backgroundColor = .Theme.charcoal
        self.loadingView.isHidden = true
        self.loadingView.layer.cornerRadius = 10
        self.loadingView.layer.masksToBounds = true
        
        self.contentView.addSubview(mainImageView)
        self.contentView.addSubview(loadingView)
        
        self.mainImageView.snp.makeConstraints { make in
            make.top.leading.equalTo(self.contentView).offset(1)
            make.bottom.trailing.equalTo(self.contentView).offset(-1)
        }
        
        self.loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.center.equalTo(self.contentView)
        }
    }
    
    
//    func configure(with photo: PhotoInAlbum) {
//        self.mainImageView.image = photo.cellImage
//    }
    func configure(with photo: PhotoInAlbum, viewModel: HomeViewModel) {
        self.assetIdentifier = photo.localIdentifier
        self.loadingView.isHidden = false
        task = Task {
            let image = await viewModel.loadImage(id: photo.localIdentifier, size: self.frame.size)
            
            // ✅ 요청한 사진이 여전히 이 셀에 필요한 사진인지 확인
            if !Task.isCancelled && self.assetIdentifier == photo.localIdentifier {
                self.mainImageView.image = image
            }
            self.loadingView.isHidden = true
        }
    }
}
