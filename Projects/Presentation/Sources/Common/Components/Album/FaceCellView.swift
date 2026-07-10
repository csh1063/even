//
//  FaceCellView.swift
//  Presentation
//
//  Created by sanghyeon on 7/9/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit

/// 얼굴 앨범 커버에서 얼굴 크롭 이미지만 담당하는 뷰
final class FaceCellView: UIView {

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
        fatalError("FaceCellView does not support NSCoding")
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

    func configure(with viewModel: FaceCellViewModel, onImageLoaded: ((Bool) -> Void)? = nil) {
        currentPhotoId = viewModel.photoId
        task = Task {
            let image = await viewModel.loadFaceImage()
            guard !Task.isCancelled, currentPhotoId == viewModel.photoId else { return }
            imageView.image = image
            onImageLoaded?(image != nil)
        }
    }
}
