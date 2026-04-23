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
    
    private let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .cyan, .purple]
    
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
        
        self.coverView.addBorder(color: Theme.border, borderWidth: 1)
        self.coverView.layer.masksToBounds = true
        self.coverView.layer.cornerRadius = 12
        
        self.mainImageView.backgroundColor = .clear
        self.mainImageView.contentMode = .scaleAspectFill
        
        self.noImageView.color = Theme.accent
        
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
        self.assetIdentifier = viewModel.localIdentifier
        self.noImageView.color = colors[index % colors.count]
        self.noImageView.startShimmer()
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
