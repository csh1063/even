//
//  ImageViewerCell.swift
//  Presentation
//
//  Created by sanghyeon on 5/7/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit

final class ImageViewerCell: UICollectionViewCell, UIScrollViewDelegate {

    static let identifier = "ImageViewerCell"

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 5.0
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.bouncesZoom = true
        sv.contentInsetAdjustmentBehavior = .never
        return sv
    }()

    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateImageFrame()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        scrollView.zoomScale = 1.0
    }

    // MARK: - Configure

    private func setupViews() {

        scrollView.delegate = self
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    func configure(image: UIImage?) {
        imageView.image = image
        scrollView.zoomScale = 1.0
        updateImageFrame()
    }

    private func updateImageFrame() {
        guard let image = imageView.image else {
            imageView.frame = scrollView.bounds
            return
        }
        let size = aspectFitSize(for: image.size, in: scrollView.bounds.size)
        imageView.frame = CGRect(
            x: max(0, (scrollView.bounds.width - size.width) / 2),
            y: max(0, (scrollView.bounds.height - size.height) / 2),
            width: size.width,
            height: size.height
        )
        scrollView.contentSize = size
    }

    private func aspectFitSize(for imageSize: CGSize, in containerSize: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return containerSize }
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    // MARK: - Double Tap Zoom

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let rect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
            scrollView.zoom(to: rect, animated: true)
        }
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
        imageView.frame.origin = CGPoint(x: offsetX, y: offsetY)
    }
}
