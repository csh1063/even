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
        view.startAnimating()
        return view
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
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateBorderColor() {
        layer.borderWidth = 1
        layer.borderColor = Theme.strokeSoft.cgColor
    }
    
    func updateProgress(_ progress: Double) {
        let width = self.frame.size.width
        UIView.animate(withDuration: 0.1) {
            self.progressView.snp.updateConstraints { make in
                make.leading.top.bottom.equalTo(self)
                make.width.equalTo(width * progress)
            }
            self.layoutIfNeeded()
        }
    }

    private func setupLayout() {
        
        iconBackground.addSubview(iconView)

        progressView.clipsToBounds = true
        
        addSubview(titleLabel)
        addSubview(progressView)
        progressView.addSubview(fillLabel)
        addSubview(iconBackground)
        addSubview(spinner)
        
        self.snp.makeConstraints { make in
            make.height.equalTo(58)
        }
        
        progressView.snp.makeConstraints { make in
            make.leading.top.bottom.equalTo(self)
            make.width.equalTo(0)
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

    }
}
