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
//        label.text = "연결된 앨범 2개"
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

    init(viewModel: ImageViewerViewModel) {
        self.viewModel = viewModel
        self.currentIndex = viewModel.currentIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.viewerBackground
        setupViews()
        bind()
        
        self.viewModel.send(.pageChanged(self.currentIndex))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollToInitialIndex()
    }
    
    private func setupViews() {
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 상단
        view.addSubview(topBarView)
        topBarView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }

        let topGradient = CAGradientLayer()
        topGradient.colors = [UIColor.black.withAlphaComponent(0.5).cgColor, UIColor.clear.cgColor]
        topGradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100)
        topBarView.layer.insertSublayer(topGradient, at: 0)

        let buttonCoverView = UIVisualEffectView(
            effect: UIBlurEffect(style: .systemUltraThinMaterialDark)
        )
        buttonCoverView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        buttonCoverView.isUserInteractionEnabled = false
        buttonCoverView.layer.cornerRadius = 20
        buttonCoverView.clipsToBounds = true
        topBarView.addSubview(buttonCoverView)
        topBarView.addSubview(dismissButton)

        buttonCoverView.snp.makeConstraints { make in
            make.edges.equalTo(dismissButton)
        }
        
        dismissButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.width.height.equalTo(40)
        }

        // 하단
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
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: self.currentIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }

    private func bind() {
        let output = viewModel.transform()

        output.currentPhoto
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photoDetail in
                if let photoDetail {
                    self?.updateInfo(with: photoDetail)
                }
            }
            .store(in: &cancellables)
        
        dismissButton.publisher(for: .touchUpInside)
            .sink(receiveValue: { _ in
                self.dismiss(animated: true)
            })
            .store(in: &cancellables)
        
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
        tap.eventPublisher
            .sink { gesture in
                self.showOverlay.toggle()
                UIView.animate(withDuration: 0.2) {
                    let alpha: CGFloat = self.showOverlay ? 1 : 0
                    let ty: CGFloat = self.showOverlay ? 0 : 20
                    self.topBarView.alpha = alpha
                    self.bottomInfoView.alpha = alpha
                    self.bottomInfoView.transform = CGAffineTransform(translationX: 0, y: self.showOverlay ? 0 : ty)
                }
            }
            .store(in: &cancellables)
        
        let pan = UIPanGestureRecognizer()
        pan.cancelsTouchesInView = false
        pan.delegate = self
        collectionView.addGestureRecognizer(pan)
        pan.eventPublisher
            .sink { gesture in
                
                switch gesture.state {
                case .began:
                    self.beganY = gesture.location(in: self.view).y
                case .ended:
                    let after = gesture.location(in: self.view).y
                    if after > self.beganY + 200 || gesture.velocity(in: self.view).y > 1000 {
                        self.dismiss(animated: true)
                    }
                default: break
                }
            }
            .store(in: &cancellables)
        
        let tapBottom = UITapGestureRecognizer()
        bottomInfoView.addGestureRecognizer(tapBottom)
        tapBottom.eventPublisher
            .sink { gesture in
                print("!!")
            }
            .store(in: &cancellables)
    }

    private func updateInfo(with photoDetail: PhotoDetail) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        if let date = photoDetail.createdDate {
            dateLabel.text = formatter.string(from: date)
        } else {
            dateLabel.text = "날짜 정보 없음"
        }
        
        if let photo = photoDetail.photo {
            albumBadge.isHidden = true
//            albumBadgeLabel.text = "연결된 앨범 2개"
            
            let components = [photo.country, photo.administrativeArea, photo.locality].compactMap { $0 }
            
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
            
            print("labels", photoDetail.labels.map {$0.name}.joined(separator: ", ")
)
            label.text = photoDetail.labels.map {"\($0.name): \($0.confidence)"}.joined(separator: ", ")
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
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(18)
        }

        return container
    }
}

// MARK: - UICollectionViewDataSource
extension ImageViewerViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.photoDetails.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageViewerCell.identifier, for: indexPath) as! ImageViewerCell
        Task {
            let image = await viewModel.loadImage(for: indexPath.item, size: collectionView.bounds.size)
            await MainActor.run {
                cell.configure(image: image)
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
    }
}

extension ImageViewerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: view)
        return abs(velocity.y) > abs(velocity.x)
    }
}
