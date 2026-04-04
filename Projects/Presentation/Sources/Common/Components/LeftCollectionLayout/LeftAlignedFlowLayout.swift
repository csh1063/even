//
//  LeftAlignedFlowLayout.swift
//  Presentation
//
//  Created by sanghyeon on 4/1/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

final class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1
        
        return attributes.map {
            guard let attr = $0.copy() as? UICollectionViewLayoutAttributes else { return $0 }
            
            // 새 줄이면 leftMargin 리셋
            if attr.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            attr.frame.origin.x = leftMargin
            leftMargin += attr.frame.width + minimumInteritemSpacing
            maxY = max(attr.frame.maxY, maxY)
            
            return attr
        }
    }
}
