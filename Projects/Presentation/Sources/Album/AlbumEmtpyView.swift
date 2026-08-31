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

    private var analysisView = GradientCardView()
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "자동 분류 앨범", bundle: .module)
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textColor = .white
        return label
    }()

    private var messageLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "날짜·여행·인물·반려동물까지\n사진을 자동으로 분류해 앨범을 만들어요", bundle: .module)
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.92)
        label.numberOfLines = 0
        return label
    }()

    private var analysisButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .white
        config.baseForegroundColor = Theme.primary
        config.image = UIImage(systemName: "sparkles")
        config.title = String(localized: "분석 시작", bundle: .module)
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)

        var titleAttr = AttributedString(String(localized: "분석 시작", bundle: .module))
        titleAttr.font = .systemFont(ofSize: 15, weight: .semibold)
        config.attributedTitle = titleAttr

        let analysisButton = UIButton(configuration: config)
        analysisButton.layer.cornerRadius = 21 // height 42 / 2
        analysisButton.layer.masksToBounds = true
        return analysisButton
    }()

    private var progressiveView = UIView(backgroundColor: Theme.surface)
    private var coverView = UIView(backgroundColor: Theme.surfaceCool)
    private var iconImageView: UIImageView = {
        let icon = UIImage(systemName: "square.stack.3d.up.fill")?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: icon)
        imageView.tintColor = Theme.secondary
        return imageView
    }()
    private var progressiveTitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "앨범이 순서대로 만들어져요", bundle: .module)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Theme.textPrimary
        return label
    }()
    private var progressiveMessageLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "날짜·여행 앨범부터 먼저 뜨고,\n나머지도 분석하는 동안 하나씩 완성돼요", bundle: .module)
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Theme.textSecondary
        label.numberOfLines = 0
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
        progressiveView.addBorder(color: Theme.strokeSoft, borderWidth: 1)
    }

    private func setupView() {

        analysisView.layer.cornerRadius = 28
        analysisView.layer.masksToBounds = true
        analysisView.colors = [
            Theme.primary,
            Theme.accent,
            Theme.secondary
        ]
        progressiveView.layer.cornerRadius = 18
        progressiveView.layer.masksToBounds = true
        progressiveView.addBorder(color: Theme.strokeSoft, borderWidth: 1)

        coverView.layer.cornerRadius = 20
        coverView.layer.masksToBounds = true

        addSubview(analysisView)
        analysisView.addSubview(titleLabel)
        analysisView.addSubview(messageLabel)
        analysisView.addSubview(analysisButton)

        addSubview(progressiveView)
        progressiveView.addSubview(coverView)
        progressiveView.addSubview(iconImageView)
        progressiveView.addSubview(progressiveTitleLabel)
        progressiveView.addSubview(progressiveMessageLabel)

        // 카드 높이를 고정값(180)으로 박아두면 메시지가 길어지거나 기기 폭이 좁아 줄바꿈이 늘어날 때
        // 텍스트가 잘려서 "..."으로 보이는 문제가 있었다 — 내부 요소들의 top~bottom 제약 체인이 이미
        // 높이를 완전히 결정하므로, 고정 높이 없이 내용에 맞춰 자연스럽게 늘어나게 둔다.
        analysisView.snp.makeConstraints { make in
            make.top.equalTo(self).offset(16)
            make.leading.trailing.equalTo(self).inset(20)
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

        progressiveView.snp.makeConstraints { make in
            make.top.equalTo(analysisView.snp.bottom).offset(20)
            make.leading.trailing.equalTo(self).inset(20)
            make.bottom.equalTo(self).inset(32)
        }

        coverView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.leading.equalTo(progressiveView).offset(16)
            make.centerY.equalTo(progressiveView)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalTo(coverView)
            make.width.height.equalTo(20)
        }

        progressiveTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverView.snp.trailing).offset(12)
            make.trailing.equalTo(progressiveView).offset(-16)
            make.top.equalTo(progressiveView).offset(16)
        }

        progressiveMessageLabel.snp.makeConstraints { make in
            make.leading.equalTo(coverView.snp.trailing).offset(12)
            make.trailing.equalTo(progressiveView).offset(-16)
            make.top.equalTo(progressiveTitleLabel.snp.bottom).offset(4)
            make.bottom.equalTo(progressiveView).offset(-16)
        }
    }

    private func setupBinding() {
        analysisButton.addTarget(self, action: #selector(didTapAnalyze), for: .touchUpInside)
    }

    @objc func didTapAnalyze() {
        self.onAnalysis?()
    }
}
