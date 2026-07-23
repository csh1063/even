//
//  AlbumSelectionOverlayView.swift
//  Presentation
//
//  Created by sanghyeon on 7/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//  메인/전체보기 화면의 앨범 셀 7종(Date/Travel/Location/Category/Face/Animal/Similar)을 전부
//  건드리지 않고, 선택 모드일 때 셀 위에 공통으로 얹는 체크마크 오버레이. 스타일은 AlbumMergeCell의
//  checkmarkView와 동일하게 맞춘다.

import UIKit
import SnapKit

final class AlbumSelectionOverlayView: UIImageView {

    init() {
        super.init(frame: .zero)
        contentMode = .scaleAspectFit
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 2
        layer.shadowOffset = CGSize(width: 0, height: 1)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("AlbumSelectionOverlayView does not support NSCoding")
    }

    func setSelected(_ isSelected: Bool) {
        image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        tintColor = isSelected ? Theme.primary : .white
    }
}

extension UICollectionViewCell {
    private static var overlayKey: UInt8 = 0

    private var selectionOverlay: AlbumSelectionOverlayView? {
        objc_getAssociatedObject(self, &Self.overlayKey) as? AlbumSelectionOverlayView
    }

    /// 선택 모드가 아니면 오버레이를 없애고, 선택 모드면 체크마크를 셀 우상단에 얹어 선택 상태를 반영한다.
    func applySelectionOverlay(isSelectionMode: Bool, isSelected: Bool) {
        guard isSelectionMode else {
            selectionOverlay?.removeFromSuperview()
            objc_setAssociatedObject(self, &Self.overlayKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }

        let overlay: AlbumSelectionOverlayView
        if let existing = selectionOverlay {
            overlay = existing
        } else {
            overlay = AlbumSelectionOverlayView()
            contentView.addSubview(overlay)
            overlay.snp.makeConstraints { make in
                make.top.trailing.equalToSuperview().inset(6)
                make.width.height.equalTo(20)
            }
            objc_setAssociatedObject(self, &Self.overlayKey, overlay, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        overlay.setSelected(isSelected)
    }
}
