//
//  CoverPhotoPreviewViewController.swift
//  Presentation
//
//  Created by sanghyeon on 9/3/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

/// "대표 사진 변경"에서 후보 사진을 고른 직후, 실제로 저장하기 전에 각 앨범 타입의 실제 셀 모양으로
/// 어떻게 보일지 미리 보여주고 취소/선택으로 확정 여부를 사용자가 직접 결정하게 한다.
/// 얼굴/동물은 실제 커버와 똑같이 얼굴/동물 부분만 크롭해서 보여준다 — 단, 그 크롭에 쓰는 boundingBox는
/// "지금 DB에 저장된 커버 사진" 기준으로만 조회되는 fetchCoverFaceBoundingBox 대신, 클러스터 전체의
/// 사진별 boundingBox 맵(fetchFaceBoundingBoxes)에서 후보 사진 id로 직접 찾는다 — 안 그러면 아직
/// 저장 전인 후보 사진에는 옛 커버의 boundingBox가 잘못 적용된다.
final class CoverPhotoPreviewViewController: UIViewController {

    var onCancel: (() -> Void)?
    var onConfirm: (() -> Void)?

    private let album: Album
    private let candidateId: String
    private let imageUseCase: PhotoImageUseCase
    private let detailUseCase: AlbumDetailUseCase

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = .black.withAlphaComponent(0.78)
        v.alpha = 0
        return v
    }()

    private let captionLabel: UILabel = {
        let lb = UILabel()
        lb.text = String(localized: "이 사진을 대표로 사용할까요?", bundle: .module)
        lb.textColor = .white
        lb.font = .systemFont(ofSize: 16, weight: .semibold)
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.alpha = 0
        return lb
    }()

    private let previewContainer: UIView = {
        let v = UIView()
        v.alpha = 0
        v.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        return v
    }()

    private let cancelButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "취소", bundle: .module)
        config.baseForegroundColor = Theme.textSecondary
        config.baseBackgroundColor = Theme.surfaceWarm
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.alpha = 0
        return btn
    }()

    private let confirmButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "선택", bundle: .module)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.primary
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.alpha = 0
        return btn
    }()

    // MARK: - Init

    init(album: Album, candidateId: String, imageUseCase: PhotoImageUseCase, detailUseCase: AlbumDetailUseCase) {
        self.album = album
        self.candidateId = candidateId
        self.imageUseCase = imageUseCase
        self.detailUseCase = detailUseCase
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("CoverPhotoPreviewViewController does not support NSCoding")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
        loadPreviewCard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(dimView)
        view.addSubview(previewContainer)
        view.addSubview(captionLabel)
        view.addSubview(cancelButton)
        view.addSubview(confirmButton)

        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        previewContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
        }

        captionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(previewContainer.snp.top).offset(-24)
            make.leading.trailing.equalToSuperview().inset(32)
        }

        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.height.equalTo(52)
            make.width.equalTo(104)
        }
        confirmButton.snp.makeConstraints { make in
            make.leading.equalTo(cancelButton.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(cancelButton)
            make.height.equalTo(52)
        }

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        let dimTap = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        dimView.addGestureRecognizer(dimTap)
    }

    private func loadPreviewCard() {
        let loader = CoverPreviewImageLoader(imageUseCase: imageUseCase)

        if album.from == "travel" {
            var previewAlbum = album
            previewAlbum.coverPhotoIdentifier = candidateId

            let cell = TravelAlbumCell(frame: CGRect(x: 0, y: 0, width: 260, height: 190))
            // TravelAlbumCell 내부의 둥근 카드(containerView)는 collectionView가 셀 크기를 먼저
            // 정해준 뒤에 그 안에서만 그려지는 걸 전제로 만들어져서, 여기처럼 콜렉션뷰 밖에서 직접
            // 띄우면 레이아웃 타이밍상 contentView의 흰 배경 모서리가 살짝 각지게 남아 보인다.
            // 셀 자체를 통째로 둥글게 잘라서 안전하게 막는다
            cell.layer.cornerRadius = 20
            cell.layer.masksToBounds = true
            previewContainer.addSubview(cell)
            cell.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.width.equalTo(260)
                make.height.equalTo(190)
            }
            cell.configure(with: TravelAlbumCellViewModel(album: previewAlbum, imageLoader: loader))
        } else {
            let circle = CoverCirclePreviewView(isAnimal: album.from == "animal")
            previewContainer.addSubview(circle)
            // circle 내부는 avatarContainer(160x160) 아래에 nameLabel이 더 붙는 구조라 전체 높이가
            // 160보다 크다 — 여기서 height까지 160으로 강제하면 avatarContainer 쪽과 충돌해서
            // 원이 찌그러져 보였다. 높이는 내부 체인(avatar + 간격 + nameLabel)이 알아서 정하게 두고,
            // 너비만 avatarContainer 폭에 맞춰준다
            circle.snp.makeConstraints { make in
                make.top.leading.trailing.bottom.equalToSuperview()
                make.width.equalTo(160)
            }
            circle.configure(name: album.isRenamed ? album.displayName : "", count: album.photoCount)

            let isAnimal = album.from == "animal"
            let clusterId = album.name
            let candidateId = candidateId
            let detailUseCase = detailUseCase
            Task { [weak circle] in
                let boxes: [String: CGRect]
                if isAnimal {
                    boxes = (try? await detailUseCase.fetchAnimalBoundingBoxes(clusterId: clusterId)) ?? [:]
                } else {
                    boxes = (try? await detailUseCase.fetchFaceBoundingBoxes(clusterId: clusterId)) ?? [:]
                }
                let image = await loader.loadCroppedImage(id: candidateId, boundingBox: boxes[candidateId], scale: isAnimal ? 1.0 : 1.3)
                circle?.setImage(image)
            }
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        animateOut { [weak self] in
            self?.dismiss(animated: false) { self?.onCancel?() }
        }
    }

    @objc private func confirmTapped() {
        animateOut { [weak self] in
            self?.dismiss(animated: false) { self?.onConfirm?() }
        }
    }

    /// 딤 → 버튼 → 사진(+안내 문구) 순서로 하나씩 나타나도록 단계별로 지연시켜서 애니메이션한다.
    /// (전체를 한 번에 페이드하면 modal의 crossDissolve 전환과 겹쳐서 딤보다 텍스트/버튼이 먼저
    /// 보이는 것처럼 느껴졌다)
    private func animateIn() {
        UIView.animate(withDuration: 0.22) {
            self.dimView.alpha = 1
        }

        UIView.animate(withDuration: 0.2, delay: 0.14, options: [.curveEaseOut]) {
            self.cancelButton.alpha = 1
            self.confirmButton.alpha = 1
        }

        UIView.animate(
            withDuration: 0.35,
            delay: 0.26,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5
        ) {
            self.captionLabel.alpha = 1
            self.previewContainer.alpha = 1
            self.previewContainer.transform = .identity
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2) {
            self.dimView.alpha = 0
            self.captionLabel.alpha = 0
            self.previewContainer.alpha = 0
            self.cancelButton.alpha = 0
            self.confirmButton.alpha = 0
        } completion: { _ in
            completion()
        }
    }
}

// MARK: - Image Loader

private struct CoverPreviewImageLoader: ImageLoadable {
    let imageUseCase: PhotoImageUseCase

    func loadImage(id: String, size: CGSize) async -> UIImage? {
        guard let cgImage: CGImage = try? await imageUseCase.loadImage(id: id, type: .specialSize(size)).cgImage else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// FaceCellViewModel/AnimalCellViewModel과 동일한 크롭 로직 — boundingBox가 없으면 원본 그대로 반환.
    /// 얼굴 박스는 사진 전체의 일부라, 화면 표시 크기로 원본을 불러오면 크롭 후 해상도가 낮아지므로
    /// 원본은 항상 넉넉한 고정 크기로 불러온다
    func loadCroppedImage(id: String, boundingBox: CGRect?, scale: CGFloat) async -> UIImage? {
        let sourceLoadSize = CGSize(width: 1024, height: 1024)
        guard let cgImage: CGImage = try? await imageUseCase.loadImage(id: id, type: .specialSize(sourceLoadSize)).cgImage else { return nil }
        guard let boundingBox, let cropped = crop(cgImage, to: boundingBox, scale: scale) else {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(cgImage: cropped)
    }

    /// boundingBox는 Vision 정규화 좌표(원점 좌하단, 0~1) 기준
    private func crop(_ image: CGImage, to boundingBox: CGRect, scale: CGFloat) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        let expandedWidth = boundingBox.width * scale
        let expandedHeight = boundingBox.height * scale
        let expandedX = boundingBox.minX - (expandedWidth - boundingBox.width) / 2
        let expandedY = boundingBox.minY - (expandedHeight - boundingBox.height) / 2

        let clampedX = max(0, expandedX)
        let clampedY = max(0, expandedY)
        let clampedWidth = min(expandedWidth, 1.0 - clampedX)
        let clampedHeight = min(expandedHeight, 1.0 - clampedY)

        let rect = CGRect(
            x: clampedX * width,
            y: (1.0 - clampedY - clampedHeight) * height,
            width: clampedWidth * width,
            height: clampedHeight * height
        )
        return image.cropping(to: rect)
    }
}

// MARK: - Circle Preview (얼굴/동물)

/// FaceAlbumCell/AnimalAlbumCell과 같은 시각적 형태(원형 아바타 + 개수 배지 + 이름)를 미리보기용으로
/// 더 크게 그린 뷰. 이미지는 실제 커버와 동일하게 얼굴/동물 부분만 크롭해서 채워진다(setImage로 주입).
private final class CoverCirclePreviewView: UIView {

    private let avatarContainer = UIView()
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    private let placeholderIcon: UIImageView
    private let countBadge = UILabel()
    private let nameLabel = UILabel()

    init(isAnimal: Bool) {
        placeholderIcon = UIImageView(image: UIImage(systemName: isAnimal ? "pawprint.fill" : "person.fill")?.withRenderingMode(.alwaysTemplate))
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("CoverCirclePreviewView does not support NSCoding")
    }

    private func setupView() {
        avatarContainer.layer.cornerRadius = 80
        avatarContainer.layer.masksToBounds = true
        avatarContainer.layer.borderWidth = 3
        avatarContainer.layer.borderColor = UIColor.white.cgColor
        avatarContainer.backgroundColor = Theme.strokeSoft
        addSubview(avatarContainer)

        placeholderIcon.tintColor = Theme.textTertiary
        placeholderIcon.contentMode = .scaleAspectFit

        avatarContainer.addSubview(imageView)
        avatarContainer.addSubview(placeholderIcon)

        countBadge.backgroundColor = Theme.primary
        countBadge.textColor = .white
        countBadge.font = .systemFont(ofSize: 12, weight: .bold)
        countBadge.textAlignment = .center
        countBadge.layer.cornerRadius = 11
        countBadge.layer.masksToBounds = true
        countBadge.layer.borderWidth = 2
        countBadge.layer.borderColor = UIColor.black.withAlphaComponent(0.55).cgColor
        addSubview(countBadge)

        nameLabel.textAlignment = .center
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        addSubview(nameLabel)

        avatarContainer.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(160)
        }
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        placeholderIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(56)
        }
        countBadge.snp.makeConstraints { make in
            make.bottom.equalTo(avatarContainer)
            make.trailing.equalTo(avatarContainer).offset(2)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(34)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarContainer.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(name: String, count: Int) {
        nameLabel.text = name
        nameLabel.isHidden = name.isEmpty
        countBadge.text = "\(count)"
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
        placeholderIcon.isHidden = image != nil
    }
}
