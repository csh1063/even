//
//  ProgressRow.swift
//  Presentation
//
//  Created by sanghyeon on 4/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

final class ProgressRow: UIView {

    private let iconBackground: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surfaceWarm
        view.layer.cornerRadius = 17
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Theme.primary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Theme.textPrimary
        return label
    }()

    private let spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = Theme.primary
        return view
    }()

    /// "자세히" 토글 — 눌리면 onToggleDetail만 알려주고, 실제 펼침/접힘 콘텐츠는 이 뷰를 들고 있는
    /// 쪽(AlbumAnalysisSheet)이 책임진다. 이 뷰는 그저 화살표 방향만 setDetailExpanded로 반영한다.
    var onToggleDetail: (() -> Void)?

    private let detailToggleButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.down", withConfiguration: config), for: .normal)
        button.tintColor = Theme.textTertiary
        return button
    }()

    private let progressView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.primary
        return view
    }()

    private let fillLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        return label
    }()

    init(icon: String, title: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        fillLabel.text = title
        backgroundColor = Theme.surface
        layer.cornerRadius = 16
        layer.masksToBounds = true
        setupLayout()
        detailToggleButton.addTarget(self, action: #selector(detailToggleTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateBorderColor() {
        layer.borderWidth = 1
        layer.borderColor = Theme.strokeSoft.cgColor
    }

    @objc private func detailToggleTapped() {
        onToggleDetail?()
    }

    /// 화살표 방향만 반영(위/아래) — 펼쳐진 콘텐츠는 이 뷰 소관이 아니다.
    func setDetailExpanded(_ expanded: Bool) {
        UIView.animate(withDuration: 0.25) {
            // 정확히 180도(.pi)는 회전 방향이 애매해질 수 있어 아주 살짝 못 미치게 돈다.
            self.detailToggleButton.transform = expanded ? CGAffineTransform(rotationAngle: .pi - 0.001) : .identity
        }
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
        fillLabel.text = title
    }

    func startSpinner() {
        spinner.startAnimating()
    }

    func stopSpinner() {
        spinner.stopAnimating()
    }

    // 시트를 닫았다 다시 열면 매번 새 ProgressRow 인스턴스가 만들어지는데, 구독 시점에 @Published가
    // 현재값을 바로 흘려보내도 이 시점엔 아직 레이아웃 전이라 self.frame.size.width가 0이라 폭 계산이
    // 틀렸다(그래서 다음 진행률 갱신 때 이번엔 진짜 폭으로 "다시 차오르는" 것처럼 보였다). self 너비에
    // 대한 비율 제약(multipliedBy)으로 바꿔서 레이아웃 시점과 무관하게 항상 정확한 폭이 나오게 했다.
    // 다만 NSLayoutConstraint의 multiplier는 생성 후 변경 불가능한 값이라 updateConstraints(상수만
    // 갈아끼움)로는 못 바꾼다 — remakeConstraints로 매번 제약을 통째로 다시 만들어야 한다("Updated
    // constraint could not find existing matching constraint to update" 크래시의 원인이었음).
    // 첫 번째 반영은 무조건 애니메이션 없이 즉시 적용해서 "0부터 다시 차는" 시각 효과 자체를 없앤다.
    private var hasSetInitialProgress = false

    func updateProgress(_ progress: Double) {
        let apply = {
            self.progressView.snp.remakeConstraints { make in
                make.leading.top.bottom.equalTo(self)
                make.width.equalTo(self).multipliedBy(CGFloat(progress))
            }
            self.layoutIfNeeded()
        }
        guard hasSetInitialProgress else {
            hasSetInitialProgress = true
            apply()
            return
        }
        UIView.animate(withDuration: 0.1, animations: apply)
    }

    private func setupLayout() {

        iconBackground.addSubview(iconView)

        progressView.clipsToBounds = true

        addSubview(titleLabel)
        addSubview(progressView)
        progressView.addSubview(fillLabel)
        addSubview(iconBackground)
        addSubview(spinner)
        addSubview(detailToggleButton)

        self.snp.makeConstraints { make in
            make.height.equalTo(58)
        }

        progressView.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(self)
            // updateProgress()가 같은 형태(self 대비 비율)의 제약으로 업데이트하므로, 처음부터 같은
            // 형태로 만들어야 updateConstraints가 상수만 안전하게 갈아끼운다.
            make.width.equalTo(self).multipliedBy(0)
        }

        iconBackground.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(12)
            make.centerY.equalTo(self)
            make.width.height.equalTo(34)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalTo(iconBackground)
            make.width.height.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackground.snp.trailing).offset(12)
            make.centerY.equalTo(self)
        }

        fillLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackground.snp.trailing).offset(12)
            make.centerY.equalTo(self)
        }

        spinner.snp.makeConstraints { make in
            make.trailing.equalTo(self).offset(-12)
            make.centerY.equalTo(self)
        }

        detailToggleButton.snp.makeConstraints { make in
            make.trailing.equalTo(spinner.snp.leading).offset(-4)
            make.centerY.equalTo(self)
            make.width.height.equalTo(28)
        }

    }
}
