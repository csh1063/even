//
//  AlbumEmtpyView.swift
//  Presentation
//
//  Created by sanghyeon on 4/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

final class AlbumEmtpyView: UIView {
    
    var onAnalysis: (() -> Void)?
    
    var publisher: AnyPublisher<UIButton, Never> {
        analysisButton.tapPublisher.eraseToAnyPublisher()
    }
    
    private var analysisView: GradientCardView = GradientCardView()
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "자동 분류 앨범"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private var messageLabel: UILabel = {
        let label = UILabel()
        label.text = "전체 사진을 분석해 관련된 사진끼리 앨범으로 정리해요"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.92)
        label.numberOfLines = 2
        return label
    }()
    
    private var analysisButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white
        config.baseForegroundColor = Theme.primary
        config.image = UIImage(systemName: "sparkles")
        config.title = "분석 시작"
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        
        var titleAttr = AttributedString("분석 시작")
        titleAttr.font = .systemFont(ofSize: 15, weight: .semibold)
        config.attributedTitle = titleAttr
        
        let analysisButton = UIButton(configuration: config)
        analysisButton.layer.cornerRadius = 21 // height 42 / 2
        analysisButton.layer.masksToBounds = true
        return analysisButton
    }()
    
    private var locationView: UIView = UIView(backgroundColor: Theme.surface)
    private var coverView: UIView = UIView(backgroundColor: Theme.surfaceCool)
    private var iconImageView: UIImageView = {
        let icon = UIImage(systemName: "location.fill.viewfinder")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: icon)
        imageView.tintColor = Theme.secondary
        return imageView
    }()
    private var locationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "위치 기반 정리는 백그라운드에서 진행돼요"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Theme.textPrimary
        return label
    }()
    private var locationMessageLabel: UILabel = {
        let label = UILabel()
        label.text = "주소 변환과 장소 기준 앨범 생성은 마이페이지에서 확인할 수 있어요"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Theme.textSecondary
        label.numberOfLines = 2
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
        setupBinding()
    }
    
    required init?(coder: NSCoder) {
        fatalError("AlbumEmtpyView does not support NSCoding.")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        analysisView.colors = [
            Theme.primary,
            Theme.accent,
            Theme.secondary
        ]
        locationView.addBorder(color: Theme.strokeSoft, borderWidth: 1)
    }
    
    private func setupView() {
        
        analysisView.layer.cornerRadius = 28
        analysisView.layer.masksToBounds = true
        analysisView.colors = [
            Theme.primary,
            Theme.accent,
            Theme.secondary
        ]
        locationView.layer.cornerRadius = 18
        locationView.layer.masksToBounds = true
        locationView.addBorder(color: Theme.strokeSoft, borderWidth: 1)
        
        coverView.layer.cornerRadius = 20
        coverView.layer.masksToBounds = true
        
        addSubview(analysisView)
        analysisView.addSubview(titleLabel)
        analysisView.addSubview(messageLabel)
        analysisView.addSubview(analysisButton)
        
        addSubview(locationView)
        locationView.addSubview(coverView)
        locationView.addSubview(iconImageView)
        locationView.addSubview(locationTitleLabel)
        locationView.addSubview(locationMessageLabel)
        
        analysisView.snp.makeConstraints { make in
            make.top.equalTo(self).offset(16)
            make.leading.trailing.equalTo(self).inset(20)
            make.height.equalTo(180)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(analysisView).offset(22)
            make.leading.trailing.equalTo(analysisView).inset(20)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.leading.trailing.equalTo(analysisView).inset(20)
        }
        
        analysisButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(14)
            make.leading.equalTo(analysisView).inset(20)
            make.height.equalTo(42)
            make.bottom.equalTo(analysisView).offset(-22)
        }
        
        locationView.snp.makeConstraints { make in
            make.top.equalTo(analysisView.snp.bottom).offset(20)
            make.leading.trailing.equalTo(self).inset(20)
            make.bottom.equalTo(self).inset(32)
        }
        
        coverView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.leading.equalTo(locationView).offset(16)
            make.centerY.equalTo(locationView)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalTo(coverView)
            make.width.height.equalTo(32)
        }
        
        locationTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverView.snp.trailing).offset(12)
            make.trailing.equalTo(locationView).offset(-16)
            make.top.equalTo(locationView).offset(16)
        }
        
        locationMessageLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverView.snp.trailing).offset(12)
            make.trailing.equalTo(locationView).offset(-16)
            make.top.equalTo(locationTitleLabel.snp.bottom).offset(4)
            make.bottom.equalTo(locationView).offset(-16)
        }
    }
    
    private func setupBinding() {
        analysisButton.addTarget(self, action: #selector(didTapAnalyze), for: .touchUpInside)
    }
    
    @objc func didTapAnalyze() {
        self.onAnalysis?()
    }
}
