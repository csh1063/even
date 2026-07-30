//
//  ImageViewerViewController.swift
//  Presentation
//
//  Created by sanghyeon on 5/7/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Combine
import Domain

final class ImageViewerViewController: UIViewController {

    private let viewModel: ImageViewerViewModel
    private var showOverlay = true
    private var cancellables = Set<AnyCancellable>()
    private var currentIndex: Int
    private var beganY: CGFloat = 0
    private var hasScrolledToInitialIndex = false

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .black
        cv.dataSource = self
        cv.delegate = self
        cv.register(ImageViewerCell.self, forCellWithReuseIdentifier: ImageViewerCell.identifier)
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()

    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()

    private let checkButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.setImage(UIImage(systemName: "circle", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.isHidden = true
        return button
    }()

    private let topBarView = UIView()
    private lazy var bottomInfoView: UIVisualEffectView = makeBottomInfoView()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let albumBadge = UIView()
    private let albumBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = Theme.primary
        return label
    }()
    private let locationIcon = UIImageView()
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()

    // MARK: - Init

    init(viewModel: ImageViewerViewModel) {
        self.viewModel = viewModel
        self.currentIndex = viewModel.currentIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.viewerBackground
        setupViews()
        bind()
        updateCheckButton(selectedIdentifiers: viewModel.selectedIdentifiers)
        viewModel.send(.appear)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // present 애니메이션이 시작되기 전, collectionView bounds가 확정되는 시점에 딱 한 번만
        // 스크롤한다. viewWillAppear + async 디스패치로는 레이아웃이 아직 안 끝났을 수 있어 가끔
        // 엉뚱한(0번) 페이지로 열리는 문제가 있었다. viewDidLayoutSubviews는 회전 등으로 이후에도
        // 계속 호출될 수 있어서, 가드 없이 매번 스크롤하면 사용자가 이미 넘긴 위치를 초기 위치로
        // 되돌리는 새 버그가 생긴다 — hasScrolledToInitialIndex로 최초 1회만 실행되게 막는다.
        guard !hasScrolledToInitialIndex, collectionView.bounds.width > 0 else { return }
        hasScrolledToInitialIndex = true
        scrollToInitialIndex()
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        view.addSubview(topBarView)
        topBarView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }

        let topGradient = CAGradientLayer()
        topGradient.colors = [UIColor.black.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]
        topGradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100)
        topBarView.layer.insertSublayer(topGradient, at: 0)

        let buttonCoverView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        buttonCoverView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        buttonCoverView.isUserInteractionEnabled = false
        buttonCoverView.layer.cornerRadius = 20
        buttonCoverView.clipsToBounds = true
        topBarView.addSubview(buttonCoverView)
        topBarView.addSubview(dismissButton)
        topBarView.addSubview(checkButton)

        buttonCoverView.snp.makeConstraints { make in make.edges.equalTo(dismissButton) }

        dismissButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.width.height.equalTo(40)
        }
        checkButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(dismissButton)
            make.width.height.equalTo(40)
        }

        view.addSubview(bottomInfoView)
        bottomInfoView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.height.equalTo(96)
        }

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(100)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }

    private func scrollToInitialIndex() {
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
    }

    private func bind() {
        let output = viewModel.transform()

        output.currentPhoto
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photoDetail in
                if let photoDetail { self?.updateInfo(with: photoDetail) }
            }
            .store(in: &cancellables)

        output.selectedIdentifiers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] identifiers in
                self?.updateCheckButton(selectedIdentifiers: identifiers)
            }
            .store(in: &cancellables)

        dismissButton.publisher(for: .touchUpInside)
            .sink { [weak self] _ in self?.dismiss(animated: true) }
            .store(in: &cancellables)

        checkButton.publisher(for: .touchUpInside)
            .sink { [weak self] _ in
                guard let self else { return }
                let currentId = viewModel.photoDetails[currentIndex].id
                viewModel.send(.toggleSelection(id: currentId))
            }
            .store(in: &cancellables)

        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
        tap.eventPublisher
            .sink { [weak self] _ in
                guard let self else { return }
                showOverlay.toggle()
                UIView.animate(withDuration: 0.2) {
                    let alpha: CGFloat = self.showOverlay ? 1 : 0
                    self.topBarView.alpha = alpha
                    self.bottomInfoView.alpha = alpha
                    self.bottomInfoView.transform = CGAffineTransform(translationX: 0, y: self.showOverlay ? 0 : 20)
                }
            }
            .store(in: &cancellables)

        let pan = UIPanGestureRecognizer()
        pan.cancelsTouchesInView = false
        pan.delegate = self
        collectionView.addGestureRecognizer(pan)
        pan.eventPublisher
            .sink { [weak self] gesture in
                guard let self else { return }
                switch gesture.state {
                case .began:
                    beganY = gesture.location(in: view).y
                case .ended:
                    let after = gesture.location(in: view).y
                    if after > beganY + 200 || gesture.velocity(in: view).y > 1000 {
                        dismiss(animated: true)
                    }
                default: break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Check Button

    private func updateCheckButton(selectedIdentifiers: Set<String>) {
        checkButton.isHidden = !viewModel.isSelectionMode
        guard viewModel.isSelectionMode else { return }

        let currentId = viewModel.photoDetails[safe: currentIndex]?.id ?? ""
        let isSelected = selectedIdentifiers.contains(currentId)
        let imageName = isSelected ? "checkmark.circle.fill" : "circle"
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        checkButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        checkButton.tintColor = isSelected ? Theme.primary : .white
    }

    // MARK: - Info

    private func updateInfo(with photoDetail: PhotoDetail) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        dateLabel.text = photoDetail.createdDate.map { formatter.string(from: $0) } ?? "날짜 정보 없음"

        if let photo = photoDetail.photo {
            albumBadge.isHidden = true
            let components = [photo.address?.country, photo.address?.administrativeArea, photo.address?.locality, photo.address?.subLocality]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .reduce(into: [String]()) { result, value in
                    if !result.contains(value) { result.append(value) }
                }

            if components.isEmpty {
                locationIcon.image = UIImage(systemName: "location.slash")
                locationIcon.tintColor = .white.withAlphaComponent(0.72)
                locationLabel.text = "위치 정보 없음"
                locationLabel.textColor = .white.withAlphaComponent(0.82)
            } else {
                locationIcon.image = UIImage(systemName: "location.fill")
                locationIcon.tintColor = Theme.secondary
                locationLabel.text = components.joined(separator: " ")
                locationLabel.textColor = .white.withAlphaComponent(0.92)
            }
            label.text = photoDetail.id + "\n" + photoDetail.labels.map { "\($0.name): \($0.confidence)" }.joined(separator: ", ")
        } else {
            albumBadge.isHidden = false
            albumBadgeLabel.text = "미분석"
            locationIcon.image = UIImage(systemName: "location.slash")
            locationIcon.tintColor = .white.withAlphaComponent(0.72)
            locationLabel.text = "분석되지 않은 사진이에요"
            locationLabel.textColor = .white.withAlphaComponent(0.82)
        }
    }

    private func makeBottomInfoView() -> UIVisualEffectView {
        let container = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        container.layer.cornerRadius = 22
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        container.clipsToBounds = true

        albumBadge.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        albumBadge.layer.cornerRadius = 13
        albumBadge.addSubview(albumBadgeLabel)
        albumBadgeLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        let topRow = UIStackView(arrangedSubviews: [dateLabel, albumBadge])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.distribution = .equalSpacing

        locationIcon.contentMode = .scaleAspectFit
        locationIcon.snp.makeConstraints { make in make.width.height.equalTo(16) }

        let locationRow = UIStackView(arrangedSubviews: [locationIcon, locationLabel])
        locationRow.axis = .horizontal
        locationRow.spacing = 8
        locationRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [topRow, locationRow])
        stack.axis = .vertical
        stack.spacing = 14

        container.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(18) }

        return container
    }
}

// MARK: - UICollectionViewDataSource

extension ImageViewerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.photoDetails.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageViewerCell.identifier, for: indexPath)
        if let imageCell = cell as? ImageViewerCell {
            Task {
                let image = await viewModel.loadImage(for: indexPath.item, size: collectionView.bounds.size)
                await MainActor.run { imageCell.configure(image: image) }
            }
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ImageViewerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        guard page != currentIndex else { return }
        currentIndex = page
        viewModel.send(.pageChanged(page))
        updateCheckButton(selectedIdentifiers: viewModel.selectedIdentifiers)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ImageViewerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: view)
        return abs(velocity.y) > abs(velocity.x)
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
