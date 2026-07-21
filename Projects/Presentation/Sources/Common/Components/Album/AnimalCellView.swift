//
//  AnimalCellView.swift
//  Presentation
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit

/// 동물 앨범 커버에서 동물 크롭 이미지만 담당하는 뷰 — FaceCellView와 동일한 패턴
final class AnimalCellView: UIView {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private var task: Task<Void, Never>?
    private var currentPhotoId: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("AnimalCellView does not support NSCoding")
    }

    private func setupView() {
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func prepareForReuse() {
        task?.cancel()
        imageView.image = nil
        currentPhotoId = nil
    }

    func configure(with viewModel: AnimalCellViewModel, onImageLoaded: ((Bool) -> Void)? = nil) {
        currentPhotoId = viewModel.photoId
        task = Task {
            let image = await viewModel.loadAnimalImage()
            guard !Task.isCancelled, currentPhotoId == viewModel.photoId else { return }
            imageView.image = image
            onImageLoaded?(image != nil)
        }
    }
}
