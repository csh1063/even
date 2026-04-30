//
//  BoxView.swift
//  Presentation
//
//  Created by sanghyeon on 4/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

class BoxView: UIView {
    
    private var position: CellPosition = .middle
    
    func applyStyle(_ position: CellPosition) {
        self.position = position
//        self.layer.sublayers?.removeAll()
        
        let path: UIBezierPath
        let radius: CGFloat = 12
        let rect = self.bounds
        
        switch position {
        case .top:
            path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: radius, height: radius))
        case .middle:
            path = UIBezierPath(rect: rect)
        case .bottom:
            path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: radius, height: radius))
        case .single:
            path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        }
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
        
        // 보더
        let border = CAShapeLayer()
        border.path = path.cgPath
        border.strokeColor = Theme.strokeSoft.cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1
        self.layer.addSublayer(border)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 여기서 applyStyle 호출하면 bounds 보장
        applyStyle(self.position)
    }
}
