//
//  FeedbackViewController.swift
//  Presentation
//
//  Created by sanghyeon on 5/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Combine

final class FeedbackViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: FeedbackViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI
    private let naviView: NaviBarView = {
        let naviView = NaviBarView()
        naviView.setTitle("문의 / 피드백")
        naviView.addButtons([
            LeftButton(type: .back)
        ])
        return naviView
    }()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let typeSegmentControl: UISegmentedControl = {
        let items = FeedbackType.allCases.map { $0.title }
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.selectedSegmentTintColor = Theme.primary
        sc.setTitleTextAttributes([.foregroundColor: Theme.textPrimary], for: .normal)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return sc
    }()

    private let textViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surface
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.strokeSoft.cgColor
        return view
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 15)
        tv.textColor = Theme.textPrimary
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        return tv
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "문의하실 내용을 입력해주세요"
        label.font = .systemFont(ofSize: 15)
        label.textColor = Theme.textTertiary
        label.numberOfLines = 0
        return label
    }()

    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 / 1000"
        label.font = .systemFont(ofSize: 12)
        label.textColor = Theme.textTertiary
        label.textAlignment = .right
        return label
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "앱 버전, 기기 정보가 함께 전송돼요"
        label.font = .systemFont(ofSize: 12)
        label.textColor = Theme.textTertiary
        return label
    }()

//    private let reviewButton: UIButton = {
//        var config = UIButton.Configuration.tinted()
//        config.title = "App Store에서 평가하기 ⭐️"
//        config.baseForegroundColor = Theme.primary
//        config.baseBackgroundColor = Theme.primary
//        config.cornerStyle = .large
//        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { container in
//            var c = container
//            c.font = .systemFont(ofSize: 15, weight: .medium)
//            return c
//        }
//        return UIButton(configuration: config)
//    }()

    private let submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "제출하기"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.primary
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { container in
            var c = container
            c.font = .systemFont(ofSize: 16, weight: .semibold)
            return c
        }
        let button = UIButton(configuration: config)
        button.isEnabled = false
        button.alpha = 0.4
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()

    // MARK: - Init

    init(viewModel: FeedbackViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        setupViews()
        setupConstraints()
        binding()
        setupKeyboardObserver()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.textView.becomeFirstResponder()
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(scrollView)
        view.addSubview(submitButton)
        view.addSubview(naviView)
        scrollView.addSubview(contentView)
        submitButton.addSubview(loadingIndicator)

        [typeSegmentControl, textViewContainer, characterCountLabel, infoLabel/*, reviewButton*/].forEach {
            contentView.addSubview($0)
        }

        [textView, placeholderLabel].forEach {
            textViewContainer.addSubview($0)
        }

        textView.delegate = self
    }

    private func setupConstraints() {

        naviView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        submitButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(54)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        scrollView.snp.makeConstraints {
//            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.top.equalTo(naviView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(submitButton.snp.top).offset(-12)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        typeSegmentControl.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(36)
        }

        textViewContainer.snp.makeConstraints {
            $0.top.equalTo(typeSegmentControl.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(200)
        }

        textView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }

        characterCountLabel.snp.makeConstraints {
            $0.top.equalTo(textViewContainer.snp.bottom).offset(6)
            $0.trailing.equalToSuperview().inset(20)
        }

        infoLabel.snp.makeConstraints {
            $0.top.equalTo(characterCountLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }

//        reviewButton.snp.makeConstraints {
//            $0.top.equalTo(infoLabel.snp.bottom).offset(24)
//            $0.leading.trailing.equalToSuperview().inset(20)
//            $0.height.equalTo(50)
//            $0.bottom.equalToSuperview().inset(20)
//        }
    }

    private func binding() {

        let output = viewModel.transForm()

        output.isSubmitEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.submitButton.isEnabled = enabled
                UIView.animate(withDuration: 0.2) {
                    self?.submitButton.alpha = enabled ? 1.0 : 0.4
                }
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.loadingIndicator.startAnimating()
                    self?.submitButton.configuration?.title = nil
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.submitButton.configuration?.title = "제출하기"
                }
                self?.submitButton.isUserInteractionEnabled = !loading
            }
            .store(in: &cancellables)

        output.submitResult
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] result in
                switch result {
                case .success:
                    self?.showSuccess()
                case .failure:
                    self?.showError()
                }
            }
            .store(in: &cancellables)

        naviView.publisher
            .sink { type in
                switch type {
                case .back:
                    self.navigationController?.popViewController(animated: true)
                default: break
                }
            }
            .store(in: &cancellables)

//        typeSegmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        typeSegmentControl.selectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                let type = FeedbackType.allCases[index]
                switch type {
                case .contact: self?.placeholderLabel.text = "문의하실 내용을 입력해주세요"
                case .feature: self?.placeholderLabel.text = "제안하실 기능을 입력해주세요"
                case .bug:     self?.placeholderLabel.text = "발생한 문제를 자세히 설명해주세요"
                }

                self?.viewModel.send(.changeSegment(type))
            }
            .store(in: &cancellables)

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
//        reviewButton.addTarget(self, action: #selector(reviewTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Actions

//    @objc private func segmentChanged() {
//        print("segmentChanged")
//        let index = typeSegmentControl.selectedSegmentIndex
//        viewModel.selectedType = FeedbackType.allCases[index]
//        updatePlaceholder()
//    }

    @objc private func submitTapped() {
        print("submitTapped")
        Task { @MainActor in
            await viewModel.submit()
        }
    }

    @objc private func reviewTapped() {
        print("reviewTapped")
        // App Store ID로 교체
        guard let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func dismissKeyboard() {
        print("dismissKeyboard")
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        print("keyboardWillShow")
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        print("keyboardWillHide")
        scrollView.contentInset.bottom = 0
    }

    // MARK: - Update

//    private func updatePlaceholder() {
//        switch viewModel.selectedType {
//        case .contact: placeholderLabel.text = "문의하실 내용을 입력해주세요"
//        case .feature: placeholderLabel.text = "제안하실 기능을 입력해주세요"
//        case .bug:     placeholderLabel.text = "발생한 문제를 자세히 설명해주세요"
//        }
//    }

    private func showSuccess() {
        let alert = UIAlertController(title: "제출 완료", message: "소중한 의견 감사해요 😊\n빠르게 검토할게요", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func showError() {
        let alert = UIAlertController(title: "제출 실패", message: "잠시 후 다시 시도해주세요", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate

extension FeedbackViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        placeholderLabel.isHidden = !text.isEmpty
        characterCountLabel.text = "\(text.count) / 1000"
//        viewModel.updateContent(text)
        self.viewModel.send(.changeText(text))
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let current = textView.text ?? ""
        let newLength = current.count + text.count - range.length
        return newLength <= 1000
    }
}
