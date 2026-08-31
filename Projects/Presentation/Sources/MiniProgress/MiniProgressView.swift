//
//  MiniProgressView.swift
//  Presentation
//
//  Created by sanghyeon on 4/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Combine

/// 사진 분석과 앨범 생성이 이제 순차가 아니라 각자 독립적으로(병렬로) 진행되기 때문에, 하나의 원을
/// 반으로 나눠 보여주던 예전 디자인(마치 앞뒤 단계처럼 보임)을 버리고, 두 줄짜리 독립 바 형태로
/// 바꿨다 — 아이콘으로 구분되는 두 개의 얇은 진행바가 각자 채워진다.
final class MiniProgressView: UIView {

    var cancellables = Set<AnyCancellable>()
    var onTap: (() -> Void)?

    private let photoRow = MiniProgressBarRow(icon: "photo.badge.plus")
    private let albumRow = MiniProgressBarRow(icon: "square.stack.3d.up.fill")

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.surface
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        setupLayout()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 176, height: 72)
    }

    @objc private func handleTap() {
        onTap?()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderWidth = 0.5
        layer.borderColor = Theme.strokeSoft.cgColor
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [photoRow, albumRow])
        stack.axis = .vertical
        stack.spacing = 12

        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(16)
            make.centerY.equalTo(self)
        }
    }

    // MARK: - Bind

    func bind(
        locationProgress: AnyPublisher<Double, Never>,
        albumProgress: AnyPublisher<Double, Never>
    ) {
        locationProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.photoRow.updateProgress(progress)
            }
            .store(in: &cancellables)

        albumProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.albumRow.updateProgress(progress)
                if progress >= 1.0 {
                    AnalysisProgressManager.shared.hide()
                }
            }
            .store(in: &cancellables)
    }
}

/// 미니 위젯 한 줄 — 아이콘 + 얇은 진행바 + 진행 중일 때만 보이는 펄스 도트(끝단).
/// 폭 계산은 self가 아니라 trackView 대비 비율(multipliedBy)로 해서 레이아웃 시점과 무관하게 항상
/// 정확하고, 첫 반영은 애니메이션 없이 즉시 적용해서 위젯이 다시 만들어질 때(시트↔미니 전환) "0부터
/// 다시 차는" 것처럼 보이지 않게 한다 — ProgressRow와 같은 이유/같은 방식.
private final class MiniProgressBarRow: UIView {

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Theme.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let trackView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.strokeSoft
        view.layer.cornerRadius = 2.5
        view.clipsToBounds = true
        return view
    }()

    private let fillView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.primary
        view.layer.cornerRadius = 2.5
        return view
    }()

    private let glowDot: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 3
        view.layer.shadowColor = Theme.primary.cgColor
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = .zero
        view.layer.shadowOpacity = 0
        view.isHidden = true
        return view
    }()

    private var hasSetInitialProgress = false

    init(icon: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: icon)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        addSubview(iconView)
        addSubview(trackView)
        trackView.addSubview(fillView)
        // glowDot은 트랙에 안 가려야 해서(트랙은 clipsToBounds) trackView가 아니라 self의 자식으로 두고
        // fillView의 오른쪽 끝을 따라가게만 제약을 건다.
        addSubview(glowDot)

        snp.makeConstraints { make in
            make.height.equalTo(14)
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.centerY.equalTo(self)
            make.width.height.equalTo(14)
        }

        trackView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.trailing.equalTo(self)
            make.centerY.equalTo(self)
            make.height.equalTo(5)
        }

        fillView.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(trackView)
            make.width.equalTo(trackView).multipliedBy(0)
        }

        glowDot.snp.makeConstraints { make in
            make.centerX.equalTo(fillView.snp.trailing)
            make.centerY.equalTo(trackView)
            make.width.height.equalTo(6)
        }
    }

    func updateProgress(_ progress: Double) {
        // NSLayoutConstraint의 multiplier는 생성 후 변경 불가능해서 updateConstraints(상수만 갈아끼움)로는
        // 못 바꾼다 — remakeConstraints로 매번 통째로 다시 만들어야 한다(안 그러면 "Updated constraint
        // could not find existing matching constraint to update" 크래시). remake는 이 뷰에 걸린 기존
        // SnapKit 제약을 전부 지우고 새로 만들기 때문에, leading/top/bottom도 같이 다시 선언해야 한다.
        let apply = {
            self.fillView.snp.remakeConstraints { make in
                make.leading.top.bottom.equalTo(self.trackView)
                make.width.equalTo(self.trackView).multipliedBy(CGFloat(progress))
            }
            self.layoutIfNeeded()
        }

        glowDot.isHidden = progress <= 0 || progress >= 1.0
        if progress > 0 && progress < 1.0 {
            startPulseIfNeeded()
        } else {
            stopPulse()
        }

        guard hasSetInitialProgress else {
            hasSetInitialProgress = true
            apply()
            return
        }
        UIView.animate(withDuration: 0.15, animations: apply)
    }

    private func startPulseIfNeeded() {
        guard glowDot.layer.animation(forKey: "pulse") == nil else { return }

        let shadowAnim = CAKeyframeAnimation(keyPath: "shadowOpacity")
        shadowAnim.values = [0.4, 0.9, 0.4]
        shadowAnim.keyTimes = [0, 0.5, 1]

        let scaleAnim = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnim.values = [0.8, 1.2, 0.8]
        scaleAnim.keyTimes = [0, 0.5, 1]

        let group = CAAnimationGroup()
        group.animations = [shadowAnim, scaleAnim]
        group.duration = 1.2
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        glowDot.layer.add(group, forKey: "pulse")
    }

    private func stopPulse() {
        glowDot.layer.removeAnimation(forKey: "pulse")
    }
}
