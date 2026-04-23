//
//  GradientCardView.swift
//  Presentation
//
//  Created by sanghyeon on 4/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

class GradientCardView: UIView {
    
    private var shimmerLayer: CAGradientLayer?
    
    var color: UIColor = .systemBlue {
        didSet { updateGradient() }
    }
    
    private let mainGradientLayer = CAGradientLayer()
    private let overlayGradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setup() {
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        clipsToBounds = true
        
        // main gradient
        mainGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        mainGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(mainGradientLayer)
        
        // overlay gradient
        overlayGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        overlayGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        overlayGradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.10).cgColor
        ]
        layer.addSublayer(overlayGradientLayer)
        
        updateGradient()
    }
    
    private func updateGradient() {
        mainGradientLayer.colors = [
            color.withAlphaComponent(0.8).cgColor,
            UIColor(named: "surfaceAlt")?.cgColor ?? UIColor.systemBackground.cgColor
        ]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        mainGradientLayer.frame = bounds
        overlayGradientLayer.frame = bounds
        shimmerLayer?.frame = bounds  // 추가
    }
    
    override var intrinsicContentSize: CGSize {
        let width = bounds.width
        return CGSize(width: width, height: width) // aspectRatio 1:1
    }
    
    func startShimmer() {
        let shimmerLayer = CAGradientLayer()
        shimmerLayer.frame = bounds
        shimmerLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 1)
        shimmerLayer.locations = [-1, -0.5, 0]
        layer.addSublayer(shimmerLayer)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        shimmerLayer.add(animation, forKey: "shimmer")
        
        self.shimmerLayer = shimmerLayer
    }

    func stopShimmer() {
        shimmerLayer?.removeFromSuperlayer()
        shimmerLayer = nil
    }
}
