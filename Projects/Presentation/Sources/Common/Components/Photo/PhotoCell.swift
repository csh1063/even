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
    
    private let colors: [UIColor] = [Theme.primary, Theme.secondary, Theme.accent]
    
    private let coverView: UIView = UIView()
    
    private let mainImageView: UIImageView = UIImageView()
    private let noImageView: GradientCardView = GradientCardView()
    
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
        
        self.coverView.layer.masksToBounds = true
        self.coverView.layer.cornerRadius = 12
        
        self.mainImageView.backgroundColor = .clear
        self.mainImageView.contentMode = .scaleAspectFill
        
        self.contentView.addSubview(coverView)
        self.coverView.addSubview(noImageView)
        self.coverView.addSubview(mainImageView)
        
        self.coverView.snp.makeConstraints { make in
            make.edges.equalTo(self.contentView)
        }
        
        self.mainImageView.snp.makeConstraints { make in
            make.edges.equalTo(self.coverView)
        }
        
        self.noImageView.snp.makeConstraints { make in
            make.edges.equalTo(self.coverView)
        }
    }
    
    func configure(with viewModel: PhotoCellItemViewModel, index: Int) {
        
        self.noImageView.colors = [
            colors[index % colors.count].withAlphaComponent(0.8),
            Theme.surfaceWarm
        ]
        self.noImageView.startShimmer()
        
        guard viewModel.localIdentifier.count > 3 else {
            return
        }
        
        self.assetIdentifier = viewModel.localIdentifier
        
        if viewModel.isUnanalysis {
            self.coverView.addBorder(color: Theme.negative, borderWidth: 1)
        } else {
            self.coverView.addBorder(color: Theme.strokeSoft, borderWidth: 1)
        }
        
        task = Task {
            let size = self.frame.size
            let image = await viewModel.loadImage(size: CGSize(
                width: size.width * 2,
                height: size.height * 2
            ))
            
            if !Task.isCancelled && self.assetIdentifier == viewModel.localIdentifier {
                self.mainImageView.image = image
            }
            self.noImageView.stopShimmer()
        }
    }
}
