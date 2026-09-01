//
//  AnalysisBadgeView.swift
//  Presentation
//
//  Created by sanghyeon on 9/2/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

/// 진행 상태 3단계(배지) — 정확한 %를 안 보여주고, 은은하게 퍼지는 펄스 링 2겹 + 작은 반짝임 아이콘으로
/// "지금 뭔가 하고 있다"만 전달한다. 이 크기에서는 두 진행률(사진 분석/앨범 생성)을 정확히 표시하기도
/// 어렵고, 이 상태로 떠 있는 동안은 사용자가 다른 화면을 보고 있을 확률이 높아서 정확한 숫자보다
/// "아직 살아있다"는 확인이 더 중요하다고 판단했다.
final class AnalysisBadgeView: UIView {

    var onTap: (() -> Void)?

    private let coreCircle: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surface
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.strokeSoft.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        return view
    }()

    private let iconView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let imageView = UIImageView(image: UIImage(systemName: "sparkle", withConfiguration: config))
        imageView.tintColor = Theme.primary
        return imageView
    }()

    private let pulseRing1 = CAShapeLayer()
    private let pulseRing2 = CAShapeLayer()

    // "완료" 상태일 때만 core 왼쪽에 나타나는 라벨 — 평소엔 폭 0으로 숨겨져 있다.
    private let completedLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "완료", bundle: .module)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = Theme.positive
        label.alpha = 0
        return label
    }()

    private var isCompleted = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupPulseLayers()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    // 40pt 원(core)만 있을 때도, "완료" 라벨이 왼쪽에 나타날 때도 뷰 자체의 크기는 고정해서(AnalysisBadgeManager가
    // 이 크기로 제약을 건다) — 라벨이 나타난다고 뷰가 커지면서 레이아웃을 다시 잡을 필요가 없게 한다.
    // core는 항상 오른쪽 끝에 붙어있고, 라벨은 그 왼쪽의 여유 공간 안에서만 보였다 안 보였다 한다.
    override var intrinsicContentSize: CGSize {
        CGSize(width: 98, height: 40)
    }

    @objc private func handleTap() {
        onTap?()
    }

    private func setupLayout() {
        addSubview(completedLabel)
        addSubview(coreCircle)
        coreCircle.addSubview(iconView)

        coreCircle.snp.makeConstraints { make in
            make.trailing.centerY.equalTo(self)
            make.width.height.equalTo(40)
        }

        iconView.snp.makeConstraints { make in
            make.center.equalTo(coreCircle)
            make.width.height.equalTo(15)
        }

        completedLabel.snp.makeConstraints { make in
            make.trailing.equalTo(coreCircle.snp.leading).offset(-6)
            make.centerY.equalTo(self)
        }
    }

    private func setupPulseLayers() {
        [pulseRing1, pulseRing2].forEach {
            $0.fillColor = UIColor.clear.cgColor
            $0.strokeColor = Theme.primary.cgColor
            $0.lineWidth = 1.4
            layer.addSublayer($0)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // pulseRing의 bounds/position을 안 맞춰주면(둘 다 기본값 .zero인 채로) transform.scale이
        // self의 원점(0,0) 기준으로 걸려서, 실제로 원이 그려지는 위치(coreCircle, 오른쪽 끝)와
        // 스케일 중심이 어긋나 "오른쪽으로 빔이 발사되는" 것처럼 보였다. bounds/position을 coreCircle의
        // 실제 프레임에 맞추고, path는 그 local 좌표계(0,0 기준) 안에 그려야 스케일이 원 중심 기준으로 걸린다.
        let localRect = CGRect(origin: .zero, size: coreCircle.frame.size)
        let path = UIBezierPath(ovalIn: localRect).cgPath
        for ring in [pulseRing1, pulseRing2] {
            ring.bounds = localRect
            ring.position = CGPoint(x: coreCircle.frame.midX, y: coreCircle.frame.midY)
            ring.path = path
        }
    }

    // MARK: - State

    /// 분석이 진행 중일 때 계속 호출 — 이미 펄스가 돌고 있으면 무시(중복 애니메이션 방지).
    func setActive() {
        guard !isCompleted else { return }
        startPulseIfNeeded()
    }

    /// 완료 시점에 한 번 호출 — 펄스를 멈추고 체크마크 + "완료" 텍스트로 바꾼다. 자동으로 사라지지
    /// 않고 탭해야 사라진다(호출부인 TabbarCoordinator가 탭 시 dismiss 처리).
    func showCompleted() {
        guard !isCompleted else { return }
        isCompleted = true

        pulseRing1.removeAllAnimations()
        pulseRing2.removeAllAnimations()
        pulseRing1.opacity = 0
        pulseRing2.opacity = 0

        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        iconView.image = UIImage(systemName: "checkmark", withConfiguration: config)
        iconView.tintColor = Theme.positive
        coreCircle.layer.borderColor = Theme.positive.cgColor

        UIView.animate(withDuration: 0.25) {
            self.completedLabel.alpha = 1
        }
    }

    private func startPulseIfNeeded() {
        guard pulseRing1.animation(forKey: "pulse") == nil else { return }
        pulseRing1.opacity = 1
        pulseRing2.opacity = 1

        for (layer, delay) in [(pulseRing1, 0.0), (pulseRing2, 1.1)] {
            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [1.0, 1.85]
            scale.keyTimes = [0, 1]

            let opacity = CAKeyframeAnimation(keyPath: "opacity")
            opacity.values = [0.55, 0]
            opacity.keyTimes = [0, 1]

            let group = CAAnimationGroup()
            group.animations = [scale, opacity]
            group.duration = 2.2
            group.beginTime = CACurrentMediaTime() + delay
            group.repeatCount = .infinity
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.fillMode = .backwards

            layer.add(group, forKey: "pulse")
        }
    }
}
