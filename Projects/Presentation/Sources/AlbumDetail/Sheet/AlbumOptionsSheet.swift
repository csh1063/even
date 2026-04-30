//
//  AlbumOptionsSheet.swift
//  Presentation
//
//  Created by sanghyeon on 4/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit

final class AlbumOptionsSheet: UIViewController {

    let albumTitle: String
    var onRename: (() -> Void)?
    var onDelete: (() -> Void)?

    private let grabberView: UIView = {
        let grabberView = UIView()
        grabberView.backgroundColor = Theme.strokeSoft
        grabberView.layer.cornerRadius = 2.5
        return grabberView
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "앨범 옵션"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = Theme.textPrimary
        return titleLabel
    }()

    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.text = albumTitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = Theme.textSecondary
        return subtitleLabel
    }()

    private lazy var renameRow = OptionRow(
        icon: "pencil.line",
        title: "앨범명 변경",
        tintColor: Theme.textPrimary
    )

    private lazy var deleteRow = OptionRow(
        icon: "trash",
        title: "앨범 삭제",
        tintColor: Theme.negative
    )
    
    init(albumTitle: String) {
        self.albumTitle = albumTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("AlbumOptionsSheet does not support NSCoding.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupBindings()
    }

    private func setupLayout() {
        
        view.backgroundColor = Theme.surface
        
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        let rowStack = UIStackView(arrangedSubviews: [renameRow, deleteRow])
        rowStack.axis = .vertical
        rowStack.spacing = 12
        
        view.addSubview(grabberView)
        view.addSubview(headerStack)
        view.addSubview(rowStack)

        grabberView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(10)
            make.centerX.equalTo(view)
            make.width.equalTo(42)
            make.height.equalTo(5)
        }
        
        headerStack.snp.makeConstraints { make in
            make.top.equalTo(grabberView.snp.bottom).offset(16)
            make.leading.trailing.equalTo(view).inset(20)
        }
        
        rowStack.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(20)
            make.leading.trailing.equalTo(view).inset(20)
        }
        
        renameRow.snp.makeConstraints { make in
            make.height.equalTo(58)
        }
        
        deleteRow.snp.makeConstraints { make in
            make.height.equalTo(58)
        }
    }

    private func setupBindings() {
        renameRow.addTarget(self, action: #selector(didTapRename), for: .touchUpInside)
        deleteRow.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)
    }
    
    @objc private func didTapRename() {
        dismiss(animated: true) { self.onRename?() }
    }

    @objc private func didTapDelete() {
        dismiss(animated: true) { self.onDelete?() }
    }
}

// MARK: - OptionRow

final class OptionRow: UIControl {

    private let iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        return iconView
    }()

    private let iconBackground = UIView()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        return l
    }()

    init(icon: String, title: String, tintColor: UIColor) {
        super.init(frame: .zero)

        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = tintColor
        titleLabel.text = title
        titleLabel.textColor = tintColor
        iconBackground.backgroundColor = tintColor.withAlphaComponent(0.1)

        setupLayout()

        backgroundColor = Theme.surface
        layer.cornerRadius = 16
        self.addBorder(color: Theme.strokeSoft, borderWidth: 1)
        layer.masksToBounds = true

        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.addBorder(color: Theme.strokeSoft, borderWidth: 1)
    }

    private func setupLayout() {
        iconBackground.isUserInteractionEnabled = false
        iconBackground.layer.cornerRadius = 18

        addSubview(iconBackground)
        iconBackground.addSubview(iconView)
        addSubview(titleLabel)
        
        iconBackground.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(14)
            make.centerY.equalTo(self)
            make.width.height.equalTo(36)
        }
        
        iconView.snp.makeConstraints { make in
            make.center.equalTo(iconBackground)
            make.width.height.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackground.snp.trailing).offset(14)
            make.trailing.equalTo(self).offset(-14)
            make.centerY.equalTo(self)
        }
    }

    @objc private func handleTouchDown() {
        alpha = 0.6
    }

    @objc private func handleTouchUp() {
        alpha = 1.0
    }
}
