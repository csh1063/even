//
//  AlbumRenameSheet.swift
//  Presentation
//
//  Created by sanghyeon on 4/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit
import Combine

final class AlbumRenameSheet: UIViewController {

    var onSave: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private var albumName: String
    
    private let grabberView: UIView = {
        let grabberView = UIView()
        grabberView.backgroundColor = Theme.strokeSoft
        grabberView.layer.cornerRadius = 2.5
        return grabberView
    }()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "앨범명 변경"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = Theme.textPrimary
        return titleLabel
    }()

    private let subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.text = "자동 생성된 앨범 이름을 원하는 이름으로 바꿀 수 있어요"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = Theme.textSecondary
        subtitleLabel.numberOfLines = 0
        return subtitleLabel
    }()

    private let fieldLabel: UILabel = {
        let fieldLabel = UILabel()
        fieldLabel.text = "앨범 이름"
        fieldLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        fieldLabel.textColor = Theme.textSecondary
        return fieldLabel
    }()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "앨범 이름 입력"
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.textColor = Theme.textPrimary
        textField.text = albumName
        textField.backgroundColor = Theme.surface
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        textField.rightViewMode = .always
        textField.layer.cornerRadius = 16
        textField.layer.borderWidth = 1
        textField.layer.borderColor = Theme.strokeSoft.cgColor
        textField.layer.masksToBounds = true
        return textField
    }()

    private lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "취소"
        config.baseForegroundColor = Theme.textPrimary
        config.background.backgroundColor = Theme.surface
        config.background.strokeColor = Theme.strokeSoft
        config.background.strokeWidth = 1
        config.background.cornerRadius = 18
        let cancelButton = UIButton(configuration: config)
        return cancelButton
    }()

    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "저장"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.primary
        config.background.cornerRadius = 18
        let saveButton = UIButton(configuration: config)
        return saveButton
    }()

    init(albumName: String) {
        self.albumName = albumName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.surface
        setupLayout()
        setupBinding()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if textField.isFirstResponder {
            textField.addBorder(color: Theme.textPrimary, borderWidth: 1)
        } else {
            textField.addBorder(color: Theme.strokeSoft, borderWidth: 1)
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        
        textField.delegate = self
        
        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 10
        buttonStack.distribution = .fillEqually

        let fieldStack = UIStackView(arrangedSubviews: [fieldLabel, textField])
        fieldStack.axis = .vertical
        fieldStack.spacing = 8

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        [grabberView, headerStack, fieldStack, buttonStack].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

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
        
        fieldStack.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(20)
            make.leading.trailing.equalTo(view).inset(20)
        }
        
        textField.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(fieldStack.snp.bottom).offset(16)
            make.leading.trailing.equalTo(view).inset(20)
            make.height.equalTo(50)
        }
    }
    
    private func setupBinding() {
        
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func didTapCancel() {
        onCancel?()
        dismiss(animated: true)
    }

    @objc private func didTapSave() {
        onSave?(textField.text ?? "")
        dismiss(animated: true)
    }
}

extension AlbumRenameSheet: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.addBorder(color: Theme.textPrimary, borderWidth: 1)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.addBorder(color: Theme.strokeSoft, borderWidth: 1)
    }
}
