//
//  PhotoCell.swift
//  Presentation
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain

final class PhotoCell: UICollectionViewCell {
    
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
        fatalError("PhotoCell does not support NSCoding")
    }
    
    func setupView() {
        
        self.mainImageView.backgroundColor = .clear
        self.mainImageView.layer.masksToBounds = true
        self.mainImageView.layer.cornerRadius = 4
        self.mainImageView.contentMode = .scaleAspectFill
        
        self.loadingView.backgroundColor = .Theme.charcoal
        self.loadingView.isHidden = true
        self.loadingView.layer.cornerRadius = 10
        self.loadingView.layer.masksToBounds = true
        
        self.contentView.addSubview(mainImageView)
        self.contentView.addSubview(loadingView)
        
        self.mainImageView.snp.makeConstraints { make in
            make.edges.equalTo(self.contentView)//.inset(1)
        }
        
        self.loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.center.equalTo(self.contentView)
        }
    }
    
    func configure(with viewModel: PhotoCellItemViewModel) {
        self.assetIdentifier = viewModel.localIdentifier
        self.loadingView.isHidden = false
        task = Task {
            let image = await viewModel.loadImage(size: self.frame.size)
            
            if !Task.isCancelled && self.assetIdentifier == viewModel.localIdentifier {
                self.mainImageView.image = image
            }
            self.loadingView.isHidden = true
        }
    }
}
