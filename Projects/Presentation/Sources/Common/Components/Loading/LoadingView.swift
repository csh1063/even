//
//  CardStackLoadingView.swift
//  Presentation
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

final class CardStackLoadingView: UIView {

    // MARK: - Properties

    private var displayLink: CADisplayLink?
    private var time: CGFloat = 0

    private struct CardConfig {
        let color: UIColor
        let x: CGFloat
        let baseY: CGFloat
        let delay: CGFloat
    }

    private let configs: [CardConfig] = [
        CardConfig(color: Theme.accent, x: 10, baseY: 14, delay: 0.0),
        CardConfig(color: Theme.secondary, x: 16, baseY: 18, delay: 0.3),
        CardConfig(color: Theme.primary, x: 22, baseY: 22, delay: 0.6),
    ]

    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 10
        button.alpha = 0
        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupDismissButton()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 60, height: 60)
    }

    // MARK: - Setup

    private func setupDismissButton() {
        addSubview(dismissButton)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dismissButton.widthAnchor.constraint(equalToConstant: 20),
            dismissButton.heightAnchor.constraint(equalToConstant: 20),
            dismissButton.topAnchor.constraint(equalTo: topAnchor, constant: -6),
            dismissButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 6)
        ])
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }

    @objc private func dismissTapped() {
        LoadingManager.shared.hide()
    }

    // MARK: - Lifecycle

    func startAnimating() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stopAnimating() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func showDismissButton() {
        UIView.animate(withDuration: 0.2) {
            self.dismissButton.alpha = 1
        }
    }

    @objc private func tick() {
        time += 0.016
        setNeedsDisplay()
    }

    // MARK: - Draw

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let W = rect.width
        let H = rect.height

        let bgColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.12, alpha: 1)
            : UIColor(white: 0.96, alpha: 1)
        bgColor.setFill()
        ctx.fillEllipse(in: CGRect(x: W/2 - 28, y: H/2 - 28, width: 56, height: 56))

        configs.forEach { config in
            let float = sin(time * 2 + config.delay * .pi * 2) * 3
            let y = config.baseY + float

            ctx.setFillColor(UIColor.black.withAlphaComponent(0.08).cgColor)
            drawRoundRect(ctx: ctx, x: config.x + 1, y: y + 1, w: 28, h: 20, r: 3)
            ctx.fillPath()

            ctx.setFillColor(config.color.cgColor)
            drawRoundRect(ctx: ctx, x: config.x, y: y, w: 28, h: 20, r: 3)
            ctx.fillPath()

            ctx.setFillColor(UIColor.white.withAlphaComponent(0.35).cgColor)
            ctx.fill(CGRect(x: config.x + 4, y: y + 5, width: 14, height: 2))
            ctx.fill(CGRect(x: config.x + 4, y: y + 9, width: 10, height: 2))
        }
    }

    private func drawRoundRect(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, r: CGFloat) {
        let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
        ctx.addPath(path.cgPath)
    }
}

// MARK: - UIColor hex

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
