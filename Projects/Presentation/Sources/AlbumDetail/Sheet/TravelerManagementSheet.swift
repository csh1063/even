//
//  TravelerManagementSheet.swift
//  Presentation
//
//  Created by sanghyeon on 7/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

/// 여행 앨범의 등장인물을 추가/삭제/이름변경까지 한 화면에서 처리하는 시트.
/// "여행자"(연결됨) / "인물 앨범"(안 됨) 두 섹션으로 나뉘고, 사진을 탭하면 섹션 간 이동(추가/삭제 예약),
/// 이름+펜 아이콘을 탭하면 바로 이름 변경(즉시 저장)된다. 스와이프/딤 탭으로는 안 닫히고
/// "닫기"(취소, 섹션 이동만 되돌림 — 이름 변경은 이미 저장된 채 유지)/"결정"(여행자 섹션을 그대로 저장)으로만 닫힌다
final class TravelerManagementSheet: UIViewController {

    // MARK: - Properties

    private var travelers: [Album]
    private var others: [Album]
    private let imageUseCase: PhotoImageUseCase
    private let albumUseCase: AlbumUseCase
    private let detailUseCase: AlbumDetailUseCase

    var onConfirm: (([UUID]) -> Void)?

    // MARK: - UI

    private let closeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "닫기"
        config.baseForegroundColor = Theme.textSecondary
        let btn = UIButton(configuration: config)
        return btn
    }()

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "여행자 관리"
        lb.font = .systemFont(ofSize: 17, weight: .semibold)
        lb.textColor = Theme.textPrimary
        return lb
    }()

    private let confirmButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = Theme.primary
        var titleAttr = AttributeContainer()
        titleAttr.font = .systemFont(ofSize: 16, weight: .bold)
        config.attributedTitle = AttributedString("결정", attributes: titleAttr)
        let btn = UIButton(configuration: config)
        return btn
    }()

    private lazy var collectionView: UICollectionView = {
        let space: CGFloat = 12
        let count: CGFloat = 3
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 4, left: 20, bottom: 20, right: 20)
        layout.minimumLineSpacing = space
        layout.minimumInteritemSpacing = space
        let width = (UIScreen.main.bounds.width - 40 - (space * (count - 1))) / count
        layout.itemSize = CGSize(width: width, height: width + 24)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(TravelerManagementCell.self, forCellWithReuseIdentifier: TravelerManagementCell.reuseIdentifier)
        cv.register(
            TravelerSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TravelerSectionHeaderView.reuseIdentifier
        )
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    // MARK: - Init

    init(travelers: [Album], others: [Album], imageUseCase: PhotoImageUseCase, albumUseCase: AlbumUseCase, detailUseCase: AlbumDetailUseCase) {
        self.travelers = travelers
        self.others = others
        self.imageUseCase = imageUseCase
        self.albumUseCase = albumUseCase
        self.detailUseCase = detailUseCase
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("TravelerManagementSheet does not support NSCoding.")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.surface
        isModalInPresentation = true
        setupLayout()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(confirmButton)
        view.addSubview(collectionView)

        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.height.equalTo(36)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(closeButton)
            make.height.equalTo(36)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(closeButton)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func confirmTapped() {
        let ids = travelers.map { $0.id }
        dismiss(animated: true) { [weak self] in self?.onConfirm?(ids) }
    }

    // MARK: - Section move

    // reloadData()는 화면 전체를 통째로 다시 그려서 셀들이 한 프레임 사라졌다 나오는 깜빡임이 생긴다 —
    // 옮겨지는 셀 하나만 delete+insert로 애니메이션되도록 performBatchUpdates를 쓴다
    private func moveToTravelers(from indexPath: IndexPath) {
        guard others.indices.contains(indexPath.item) else { return }
        let person = others.remove(at: indexPath.item)
        travelers.append(person)

        let destination = IndexPath(item: travelers.count - 1, section: 0)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [indexPath])
            collectionView.insertItems(at: [destination])
        }
    }

    private func moveToOthers(from indexPath: IndexPath) {
        guard travelers.indices.contains(indexPath.item) else { return }
        let person = travelers.remove(at: indexPath.item)
        // 방금 뺀 사람이 "인물 앨범" 목록에서 바로 눈에 띄도록 맨 뒤가 아니라 맨 앞에 붙인다
        others.insert(person, at: 0)

        let destination = IndexPath(item: 0, section: 1)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [indexPath])
            collectionView.insertItems(at: [destination])
        }
    }

    // MARK: - Rename

    private func presentRename(for person: Album, section: Int, index: Int) {
        let renameSheet = AlbumRenameSheet(
            albumName: person.isRenamed ? person.displayName : "",
            title: "이름 변경",
            subtitle: "이름을 정해주세요"
        )
        renameSheet.onSave = { [weak self] newName in
            guard let self, !newName.isEmpty else { return }
            Task {
                try? await self.detailUseCase.editAlbumName(new: newName, id: person.id)
                if section == 0, self.travelers.indices.contains(index) {
                    self.travelers[index].displayName = newName
                    self.travelers[index].isRenamed = true
                } else if section == 1, self.others.indices.contains(index) {
                    self.others[index].displayName = newName
                    self.others[index].isRenamed = true
                }
                // 이름 바뀐 셀 하나만 갱신 — reloadData()로 전체를 다시 그리면 깜빡인다
                self.collectionView.reloadItems(at: [IndexPath(item: index, section: section)])
            }
        }

        if let presentation = renameSheet.sheetPresentationController {
            presentation.detents = [.custom { _ in 260 }]
            presentation.preferredCornerRadius = 28
        }

        present(renameSheet, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension TravelerManagementSheet: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 0 ? travelers.count : others.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TravelerManagementCell.reuseIdentifier, for: indexPath
        ) as? TravelerManagementCell else {
            return UICollectionViewCell()
        }

        let person = indexPath.section == 0 ? travelers[indexPath.item] : others[indexPath.item]
        let faceViewModel = FaceCellViewModel(
            albumId: person.id,
            photoId: person.coverPhotoIdentifier ?? "",
            imageUseCase: imageUseCase,
            albumUseCase: albumUseCase
        )
        cell.configure(with: faceViewModel, name: person.displayName, isRenamed: person.isRenamed)

        cell.onTapPhoto = { [weak self] in
            guard let self else { return }
            if indexPath.section == 0 {
                self.moveToOthers(from: indexPath)
            } else {
                self.moveToTravelers(from: indexPath)
            }
        }
        cell.onTapRename = { [weak self] in
            self?.presentRename(for: person, section: indexPath.section, index: indexPath.item)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TravelerSectionHeaderView.reuseIdentifier,
                for: indexPath
              ) as? TravelerSectionHeaderView else {
            return UICollectionReusableView()
        }
        header.configure(title: indexPath.section == 0 ? "여행자" : "인물 앨범")
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TravelerManagementSheet: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 32)
    }
}

// MARK: - TravelerSectionHeaderView

private final class TravelerSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "TravelerSectionHeaderView"

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 15, weight: .bold)
        lb.textColor = Theme.textPrimary
        return lb
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-6)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String) {
        titleLabel.text = title
    }
}

// MARK: - TravelerManagementCell

private final class TravelerManagementCell: UICollectionViewCell {
    static let reuseIdentifier = "TravelerManagementCell"

    private let faceCellView = FaceCellView()
    private let nameRow = UIView()

    private let nameLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 12, weight: .medium)
        return lb
    }()

    private let penIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        iv.image = UIImage(systemName: "pencil", withConfiguration: config)?.withRenderingMode(.alwaysTemplate)
        iv.tintColor = Theme.textTertiary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    var onTapPhoto: (() -> Void)?
    var onTapRename: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        faceCellView.prepareForReuse()
        onTapPhoto = nil
        onTapRename = nil
    }

    func configure(with viewModel: FaceCellViewModel, name: String, isRenamed: Bool) {
        faceCellView.configure(with: viewModel)
        nameLabel.text = isRenamed ? name : "미정"
        nameLabel.textColor = isRenamed ? Theme.textPrimary : Theme.textTertiary
    }

    private func setupLayout() {
        faceCellView.layer.cornerRadius = 14
        faceCellView.layer.masksToBounds = true
        faceCellView.isUserInteractionEnabled = true

        contentView.addSubview(faceCellView)
        contentView.addSubview(nameRow)
        nameRow.addSubview(nameLabel)
        nameRow.addSubview(penIcon)

        faceCellView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(faceCellView.snp.width)
        }
        nameRow.snp.makeConstraints { make in
            make.top.equalTo(faceCellView.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(penIcon.snp.leading).offset(-4)
        }
        penIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        let photoTap = UITapGestureRecognizer(target: self, action: #selector(handlePhotoTap))
        faceCellView.addGestureRecognizer(photoTap)

        nameRow.isUserInteractionEnabled = true
        let renameTap = UITapGestureRecognizer(target: self, action: #selector(handleRenameTap))
        nameRow.addGestureRecognizer(renameTap)
    }

    @objc private func handlePhotoTap() { onTapPhoto?() }
    @objc private func handleRenameTap() { onTapRename?() }
}
