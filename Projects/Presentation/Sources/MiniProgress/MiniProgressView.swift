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
    }
    
    private func updateBorder() {
        layer.borderWidth = 0.5
        layer.borderColor = Theme.strokeSoft.cgColor
    }
    
    private func updatePaths() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius: CGFloat = 26
        
        // 위 반원 (위치) - 왼쪽에서 오른쪽으로
        let topPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        locationTrackLayer.path = topPath.cgPath
        locationProgressLayer.path = topPath.cgPath
        
        // 아래 반원 (폴더) - 오른쪽에서 왼쪽으로
        let bottomPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi,
            clockwise: true
        )
        folderTrackLayer.path = bottomPath.cgPath
        folderProgressLayer.path = bottomPath.cgPath
        
        // 구분선
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: center.x - 22, y: center.y))
        dividerPath.addLine(to: CGPoint(x: center.x + 22, y: center.y))
        dividerLayer.path = dividerPath.cgPath
    }
    
    // MARK: - Bind
    
    func bind(
        locationProgress: AnyPublisher<Double, Never>,
        folderProgress: AnyPublisher<Double, Never>
    ) {
        locationProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.locationProgressLayer.strokeEnd = CGFloat(progress)
            }
            .store(in: &cancellables)
        
        folderProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.folderProgressLayer.strokeEnd = CGFloat(progress)
                if progress >= 1.0 {
                    AnalysisProgressManager.shared.hide()
                }
            }
            .store(in: &cancellables)
    }
}
