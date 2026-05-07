//
//  MiniProgressView.swift
//  Presentation
//
//  Created by sanghyeon on 4/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Combine

final class MiniProgressView: UIView {
    
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Layers
    
    private let locationTrackLayer = CAShapeLayer()
    private let locationProgressLayer = CAShapeLayer()
    private let folderTrackLayer = CAShapeLayer()
    private let folderProgressLayer = CAShapeLayer()
    private let dividerLayer = CAShapeLayer()
    private let locationGlowLayer = CALayer()
    private let folderGlowLayer = CALayer()
    
    private let locationIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "location.fill"))
        imageView.tintColor = Theme.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let folderIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "folder.fill"))
        imageView.tintColor = Theme.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.surface
        layer.cornerRadius = 36
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        setupLayers()
        setupGlowDots()
        setupIcons()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: 72, height: 72)
    }
    
    // MARK: - Setup
    
    private func setupLayers() {
        [locationTrackLayer, locationProgressLayer,
         folderTrackLayer, folderProgressLayer,
         dividerLayer].forEach { layer.addSublayer($0) }
        
        let trackColor = Theme.strokeSoft.cgColor
        let progressColor = Theme.primary.cgColor
        
        locationTrackLayer.fillColor = UIColor.clear.cgColor
        locationTrackLayer.strokeColor = trackColor
        locationTrackLayer.lineWidth = 4
        locationTrackLayer.lineCap = .round
        
        locationProgressLayer.fillColor = UIColor.clear.cgColor
        locationProgressLayer.strokeColor = progressColor
        locationProgressLayer.lineWidth = 4
        locationProgressLayer.lineCap = .round
        locationProgressLayer.strokeEnd = 0
        
        folderTrackLayer.fillColor = UIColor.clear.cgColor
        folderTrackLayer.strokeColor = trackColor
        folderTrackLayer.lineWidth = 4
        folderTrackLayer.lineCap = .round
        
        folderProgressLayer.fillColor = UIColor.clear.cgColor
        folderProgressLayer.strokeColor = progressColor
        folderProgressLayer.lineWidth = 4
        folderProgressLayer.lineCap = .round
        folderProgressLayer.strokeEnd = 0
        
        dividerLayer.strokeColor = trackColor
        dividerLayer.lineWidth = 0.5
    }
    
    private func setupGlowDots() {
        [locationGlowLayer, folderGlowLayer].forEach {
            $0.bounds = CGRect(x: 0, y: 0, width: 6, height: 6)
            $0.cornerRadius = 3
            $0.backgroundColor = UIColor.white.cgColor
            $0.shadowColor = Theme.primary.cgColor
            $0.shadowRadius = 4
            $0.shadowOpacity = 0
            $0.shadowOffset = .zero
            $0.isHidden = true
            layer.addSublayer($0)
        }
    }
    
    private func setupIcons() {
        addSubview(locationIconView)
        addSubview(folderIconView)
        
        locationIconView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self).offset(16)
            make.width.height.equalTo(13)
        }
        
        folderIconView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-16)
            make.width.height.equalTo(13)
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBorder()
        updatePaths()
        updateGlowDot(glowLayer: locationGlowLayer, progress: locationProgressLayer.strokeEnd, startAngle: .pi)
        updateGlowDot(glowLayer: folderGlowLayer, progress: folderProgressLayer.strokeEnd, startAngle: 0)
    }
    
    private func updateBorder() {
        layer.borderWidth = 0.5
        layer.borderColor = Theme.strokeSoft.cgColor
    }
    
    private func updatePaths() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = 26
        
        let topPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        locationTrackLayer.path = topPath.cgPath
        locationProgressLayer.path = topPath.cgPath
        
        let bottomPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi,
            clockwise: true
        )
        folderTrackLayer.path = bottomPath.cgPath
        folderProgressLayer.path = bottomPath.cgPath
        
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: center.x - 22, y: center.y))
        dividerPath.addLine(to: CGPoint(x: center.x + 22, y: center.y))
        dividerLayer.path = dividerPath.cgPath
    }
    
    // MARK: - Glow Dot
    
    private func arcPoint(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
    
    private func updateGlowDot(glowLayer: CALayer, progress: CGFloat, startAngle: CGFloat) {
        guard progress > 0 else {
            glowLayer.isHidden = true
            return
        }
        glowLayer.isHidden = false
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let angle = startAngle + .pi * progress
        let point = arcPoint(center: center, radius: 26, angle: angle)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glowLayer.position = point
        CATransaction.commit()
    }
    
    private func startPulseAnimation(on glowLayer: CALayer) {
        guard glowLayer.animation(forKey: "pulse") == nil else { return }
        
        let shadowAnim = CAKeyframeAnimation(keyPath: "shadowOpacity")
        shadowAnim.values = [0.4, 0.9, 0.4]
        shadowAnim.keyTimes = [0, 0.5, 1]
        
        let shadowRadiusAnim = CAKeyframeAnimation(keyPath: "shadowRadius")
        shadowRadiusAnim.values = [2, 8, 2]
        shadowRadiusAnim.keyTimes = [0, 0.5, 1]
        
        let scaleAnim = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnim.values = [0.8, 1.2, 0.8]
        scaleAnim.keyTimes = [0, 0.5, 1]
        
        let group = CAAnimationGroup()
        group.animations = [shadowAnim, shadowRadiusAnim, scaleAnim]
        group.duration = 1.2
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        glowLayer.add(group, forKey: "pulse")
    }
    
    // MARK: - Bind
    
    func bind(
        locationProgress: AnyPublisher<Double, Never>,
        folderProgress: AnyPublisher<Double, Never>
    ) {
        locationProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self else { return }
                self.locationProgressLayer.strokeEnd = CGFloat(progress)
                self.updateGlowDot(glowLayer: self.locationGlowLayer, progress: CGFloat(progress), startAngle: .pi)
                if progress > 0 { self.startPulseAnimation(on: self.locationGlowLayer) }
            }
            .store(in: &cancellables)
        
        folderProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self else { return }
                self.folderProgressLayer.strokeEnd = CGFloat(progress)
                self.updateGlowDot(glowLayer: self.folderGlowLayer, progress: CGFloat(progress), startAngle: 0)
                if progress > 0 {
                    self.startPulseAnimation(on: self.folderGlowLayer)
                    locationGlowLayer.removeAnimation(forKey: "pulse")
                    locationGlowLayer.isHidden = true
                }

                if progress >= 1.0 {
                    AnalysisProgressManager.shared.hide()
                }
            }
            .store(in: &cancellables)
    }
}
