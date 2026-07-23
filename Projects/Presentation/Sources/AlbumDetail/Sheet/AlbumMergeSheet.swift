//
//  AlbumMergeSheet.swift
//  Presentation
//
//  Created by sanghyeon on 7/10/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

/// 현재 앨범과 합칠 동일 인물 앨범을 커버 사진 그리드에서 여러 개 골라 한 번에 합치기 위한 시트
/// centroid 유사도 0.5를 넘는 후보만 "닮은 사람" 헤더 + 구분선으로 따로 보여주고,
/// 나머지는 굳이 "기타"처럼 단정짓는 라벨 없이 원래 그리드처럼 그냥 보여준다
final class AlbumMergeSheet: UIViewController {

    private struct MergeSection {
        let title: String?
        let items: [AlbumMergeCandidate]
        let showsFooterDivider: Bool
    }

    // MARK: - Properties

    private static let similarThreshold: Float = 0.5

    private let sections: [MergeSection]
    private let imageUseCase: PhotoImageUseCase
    private let albumUseCase: AlbumUseCase
    private let isTravel: Bool
    private var selectedIds: Set<UUID> = []

    var onConfirm: (([UUID]) -> Void)?

    static let dateRangeFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale(identifier: "ko")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static func dateRangeText(for album: Album) -> String? {
        guard let start = album.startDate, let end = album.endDate else { return nil }
        return dateRangeFormatter.string(from: start, to: end)
    }

    // MARK: - UI

    private let grabberView: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.strokeSoft
        v.layer.cornerRadius = 2.5
        return v
    }()

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 20, weight: .bold)
        lb.textColor = Theme.textPrimary
        return lb
    }()

    private let subtitleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "선택하는 앨범들을 현재 앨범과 한 번에 합쳐요"
        lb.font = .systemFont(ofSize: 14, weight: .regular)
        lb.textColor = Theme.textSecondary
        lb.numberOfLines = 0
        return lb
    }()

    // 얼굴 앨범은 사진만 봐도 구분되지만, 여행은 이름/기간을 봐야 어떤 여행인지 알 수 있어서
    // 2줄(이름+기간)만큼 셀 높이를 늘려서 보여준다
    private static let travelInfoHeight: CGFloat = 40

    private lazy var collectionView: UICollectionView = {
        let space: CGFloat = 12
        // 여행은 이름/기간 텍스트가 셀 안에 들어가야 해서 한 줄에 2개만 두어 셀 폭을 넓힌다
        // (얼굴/동물 합치기는 사진만 보여주면 되니 그대로 3개)
        let count: CGFloat = isTravel ? 2 : 3
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 4, left: 20, bottom: 20, right: 20)
        layout.minimumLineSpacing = space
        layout.minimumInteritemSpacing = space
        let width = (UIScreen.main.bounds.width - 40 - (space * (count - 1))) / count
        let height = isTravel ? width + Self.travelInfoHeight : width
        layout.itemSize = CGSize(width: width, height: height)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(AlbumMergeCell.self, forCellWithReuseIdentifier: AlbumMergeCell.reuseIdentifier)
        cv.register(
            AlbumMergeSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: AlbumMergeSectionHeaderView.reuseIdentifier
        )
        cv.register(
            AlbumMergeSectionFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: AlbumMergeSectionFooterView.reuseIdentifier
        )
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private let confirmButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "선택한 앨범 합치기"
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.primary
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        return btn
    }()

    // MARK: - Init

    init(
        candidates: [AlbumMergeCandidate],
        title: String = "동일 인물 앨범 선택",
        subtitle: String? = nil,
        sectionHeaderText: String? = nil,
        isTravel: Bool = false,
        imageUseCase: PhotoImageUseCase,
        albumUseCase: AlbumUseCase
    ) {
        let similar = candidates.filter { $0.similarity > Self.similarThreshold }
        let others = candidates.filter { $0.similarity <= Self.similarThreshold }

        var sections: [MergeSection] = []
        if !similar.isEmpty {
            sections.append(MergeSection(title: "닮은 사람", items: similar, showsFooterDivider: !others.isEmpty))
        }
        if !others.isEmpty {
            sections.append(MergeSection(title: sectionHeaderText, items: others, showsFooterDivider: false))
        }
        self.sections = sections

        self.imageUseCase = imageUseCase
        self.albumUseCase = albumUseCase
        self.isTravel = isTravel
        super.init(nibName: nil, bundle: nil)
        self.titleLabel.text = title
        if let subtitle {
            self.subtitleLabel.text = subtitle
        }
    }

    required init?(coder: NSCoder) {
        fatalError("AlbumMergeSheet does not support NSCoding.")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        updateConfirmButton()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.backgroundColor = Theme.surface

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4

        view.addSubview(grabberView)
        view.addSubview(headerStack)
        view.addSubview(collectionView)
        view.addSubview(confirmButton)

        grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(5)
        }
        headerStack.snp.makeConstraints { make in
            make.top.equalTo(grabberView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(confirmButton.snp.top).offset(-12)
        }
        confirmButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(32)
            make.height.equalTo(52)
        }

        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }

    private func updateConfirmButton() {
        let count = selectedIds.count
        confirmButton.isEnabled = count > 0
        confirmButton.alpha = count > 0 ? 1.0 : 0.4
        confirmButton.configuration?.title = count > 0 ? "선택한 앨범 합치기 (\(count))" : "선택한 앨범 합치기"
    }

    // MARK: - Actions

    @objc private func confirmTapped() {
        let ids = Array(selectedIds)
        dismiss(animated: true) { [weak self] in self?.onConfirm?(ids) }
    }
}

// MARK: - UICollectionViewDataSource

extension AlbumMergeSheet: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AlbumMergeCell.reuseIdentifier, for: indexPath
        ) as? AlbumMergeCell else {
            return UICollectionViewCell()
        }

        let album = sections[indexPath.section].items[indexPath.item].album
        cell.setSelected(selectedIds.contains(album.id))

        if isTravel {
            cell.configure(album: album, imageUseCase: imageUseCase, albumUseCase: albumUseCase, name: album.displayName, dateRangeText: Self.dateRangeText(for: album))
        } else {
            cell.configure(album: album, imageUseCase: imageUseCase, albumUseCase: albumUseCase)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let title = sections[indexPath.section].title,
                  let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: AlbumMergeSectionHeaderView.reuseIdentifier,
                    for: indexPath
                  ) as? AlbumMergeSectionHeaderView else {
                return UICollectionReusableView()
            }
            header.configure(title: title)
            return header

        case UICollectionView.elementKindSectionFooter:
            guard let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: AlbumMergeSectionFooterView.reuseIdentifier,
                for: indexPath
            ) as? AlbumMergeSectionFooterView else {
                return UICollectionReusableView()
            }
            return footer

        default:
            return UICollectionReusableView()
        }
    }
}

// MARK: - UICollectionViewDelegate

extension AlbumMergeSheet: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let album = sections[indexPath.section].items[indexPath.item].album
        if selectedIds.contains(album.id) {
            selectedIds.remove(album.id)
        } else {
            selectedIds.insert(album.id)
        }
        collectionView.reloadItems(at: [indexPath])
        updateConfirmButton()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension AlbumMergeSheet: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard sections[section].title != nil else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: 32)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard sections[section].showsFooterDivider else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: 21)
    }
}

// MARK: - AlbumMergeSectionHeaderView

private final class AlbumMergeSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "AlbumMergeSectionHeaderView"

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

// MARK: - AlbumMergeSectionFooterView

private final class AlbumMergeSectionFooterView: UICollectionReusableView {
    static let reuseIdentifier = "AlbumMergeSectionFooterView"

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.strokeSoft
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - AlbumMergeCell

private final class AlbumMergeCell: UICollectionViewCell {
    static let reuseIdentifier = "AlbumMergeCell"

    // 합치기 후보에 사람/동물 앨범이 섞일 수 있어서, 두 크롭 뷰를 겹쳐두고 종에 맞는 쪽만 보여준다
    private let faceCellView = FaceCellView()
    private let animalCellView = AnimalCellView()

    private let checkmarkView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.shadowColor = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.3
        iv.layer.shadowRadius = 2
        iv.layer.shadowOffset = CGSize(width: 0, height: 1)
        return iv
    }()

    // 여행 합치기에서만 쓰는 이름/기간 라벨 — 얼굴 합치기는 사진만으로 충분해 nil로 둔다
    private let nameLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 12, weight: .semibold)
        lb.textColor = Theme.textPrimary
        lb.textAlignment = .center
        lb.numberOfLines = 1
        return lb
    }()

    private let dateLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 11, weight: .regular)
        lb.textColor = Theme.textSecondary
        lb.textAlignment = .center
        lb.numberOfLines = 1
        return lb
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        faceCellView.prepareForReuse()
        animalCellView.prepareForReuse()
        nameLabel.text = nil
        dateLabel.text = nil
    }

    func configure(album: Album, imageUseCase: PhotoImageUseCase, albumUseCase: AlbumUseCase, name: String? = nil, dateRangeText: String? = nil) {
        let isAnimal = album.from == "animal"
        faceCellView.isHidden = isAnimal
        animalCellView.isHidden = !isAnimal

        if isAnimal {
            let viewModel = AnimalCellViewModel(
                albumId: album.id,
                photoId: album.coverPhotoIdentifier ?? "",
                imageUseCase: imageUseCase,
                albumUseCase: albumUseCase
            )
            animalCellView.configure(with: viewModel)
        } else {
            let viewModel = FaceCellViewModel(
                albumId: album.id,
                photoId: album.coverPhotoIdentifier ?? "",
                imageUseCase: imageUseCase,
                albumUseCase: albumUseCase
            )
            faceCellView.configure(with: viewModel)
        }

        nameLabel.text = name
        dateLabel.text = dateRangeText
    }

    func setSelected(_ isSelected: Bool) {
        faceCellView.layer.borderWidth = isSelected ? 3 : 0
        faceCellView.layer.borderColor = Theme.primary.cgColor
        animalCellView.layer.borderWidth = isSelected ? 3 : 0
        animalCellView.layer.borderColor = Theme.primary.cgColor
        checkmarkView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        checkmarkView.tintColor = isSelected ? Theme.primary : .white
    }

    private func setupLayout() {
        faceCellView.layer.cornerRadius = 14
        faceCellView.layer.masksToBounds = true
        faceCellView.clipsToBounds = true

        animalCellView.layer.cornerRadius = 14
        animalCellView.layer.masksToBounds = true
        animalCellView.clipsToBounds = true

        contentView.addSubview(faceCellView)
        contentView.addSubview(animalCellView)
        contentView.addSubview(checkmarkView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(dateLabel)

        faceCellView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(faceCellView.snp.width)
        }
        animalCellView.snp.makeConstraints { make in
            make.edges.equalTo(faceCellView)
        }
        checkmarkView.snp.makeConstraints { make in
            make.top.trailing.equalTo(faceCellView).inset(6)
            make.width.height.equalTo(20)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(faceCellView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
}
