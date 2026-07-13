//
//  TravelPhotoPickerViewController.swift
//  Presentation
//
//  Created by sanghyeon on 7/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

/// 여행 앨범에 사진을 수동으로 추가하는 2단계 마법사의 한 화면.
/// direction이 .before면 "이전 사진 선택"(X/다음), .after면 "다음 사진 선택"(이전/추가)이 된다
final class TravelPhotoPickerViewController: UIViewController {

    // MARK: - Callbacks

    var onCancel: (() -> Void)?
    var onNext: (([PhotoInAlbum]) -> Void)?
    var onBack: (() -> Void)?
    var onFinish: (() -> Void)?

    // MARK: - Properties

    private let viewModel: TravelPhotoPickerViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>!

    // MARK: - UI

    private let leadingButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = Theme.textSecondary
        let btn = UIButton(configuration: config)
        return btn
    }()

    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 17, weight: .semibold)
        lb.textColor = Theme.textPrimary
        return lb
    }()

    private let trailingButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = Theme.primary
        let btn = UIButton(configuration: config)
        return btn
    }()

    private lazy var collectionView: UICollectionView = {
        let space: CGFloat = 2
        let count: CGFloat = 3
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = .zero
        layout.minimumLineSpacing = space
        layout.minimumInteritemSpacing = space
        let width = (UIScreen.main.bounds.width - (space * (count + 1))) / count
        layout.itemSize = CGSize(width: width, height: width)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.contentInset = UIEdgeInsets(top: 8, left: space, bottom: 24, right: space)
        cv.backgroundColor = .clear
        cv.delegate = self
        // 길게 누른 채로 드래그하면 지나가는 셀들이 쭉 선택되는 네이티브 멀티 셀렉션 제스처
        cv.allowsMultipleSelection = true
        cv.isEditing = true
        cv.allowsMultipleSelectionDuringEditing = true
        return cv
    }()

    // MARK: - Init

    init(viewModel: TravelPhotoPickerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("TravelPhotoPickerViewController does not support NSCoding.")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.background
        setupLayout()
        setupTopBar()
        configureDataSource()

        viewModel.onPhotosUpdated = { [weak self] in self?.applySnapshot() }
        Task { await viewModel.loadFirstPageIfNeeded() }
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(leadingButton)
        view.addSubview(titleLabel)
        view.addSubview(trailingButton)
        view.addSubview(collectionView)

        leadingButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.height.equalTo(36)
        }
        trailingButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(leadingButton)
            make.height.equalTo(36)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(leadingButton)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(leadingButton.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupTopBar() {
        titleLabel.text = viewModel.direction.title

        switch viewModel.direction {
        case .before:
            leadingButton.configuration?.image = UIImage(systemName: "xmark")
            leadingButton.configuration?.title = nil
            var trailingTitleAttr = AttributeContainer()
            trailingTitleAttr.font = .systemFont(ofSize: 16, weight: .semibold)
            trailingButton.configuration?.attributedTitle = AttributedString("다음", attributes: trailingTitleAttr)
        case .after:
            var leadingTitleAttr = AttributeContainer()
            leadingTitleAttr.font = .systemFont(ofSize: 16, weight: .regular)
            leadingButton.configuration?.attributedTitle = AttributedString("이전", attributes: leadingTitleAttr)
            var trailingTitleAttr = AttributeContainer()
            trailingTitleAttr.font = .systemFont(ofSize: 16, weight: .bold)
            trailingButton.configuration?.attributedTitle = AttributedString("추가", attributes: trailingTitleAttr)
        }

        leadingButton.addTarget(self, action: #selector(leadingTapped), for: .touchUpInside)
        trailingButton.addTarget(self, action: #selector(trailingTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func leadingTapped() {
        switch viewModel.direction {
        case .before: onCancel?()
        case .after: onBack?()
        }
    }

    @objc private func trailingTapped() {
        switch viewModel.direction {
        case .before:
            onNext?(viewModel.accumulatedSelections)
        case .after:
            trailingButton.isEnabled = false
            Task {
                do {
                    try await viewModel.commit()
                    onFinish?()
                } catch {
                    trailingButton.isEnabled = true
                }
            }
        }
    }
}

// MARK: - DataSource

extension TravelPhotoPickerViewController {
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PhotoCell, PhotoCellItemViewModel> { [weak self] cell, indexPath, cellViewModel in
            guard let self else { return }
            cell.configure(with: cellViewModel, index: indexPath.row)
            cell.setSelectionMode(true)
            cell.setSelected(viewModel.selectedIds.contains(cellViewModel.localIdentifier))
            // collectionView가 isEditing + allowsMultipleSelectionDuringEditing 상태라, 탭 한 번이든
            // 길게 눌러서 드래그로 여러 개든 전부 didSelectItemAt/didDeselectItemAt으로 들어온다 —
            // 여기서 별도로 탭을 처리하면 두 경로가 겹쳐서 토글이 두 번 일어날 수 있어 비워둔다
        }

        dataSource = UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>(collectionView: collectionView) { cv, indexPath, vm in
            cv.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: vm)
        }
    }

    private func applySnapshot() {
        let items = viewModel.photos.map {
            PhotoCellItemViewModel(localIdentifier: $0.localIdentifier, imageLoader: viewModel)
        }
        var snapshot = NSDiffableDataSourceSnapshot<Int, PhotoCellItemViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDelegate

extension TravelPhotoPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        Task { await viewModel.loadMoreIfNeeded(currentIndex: indexPath.item) }
    }

    // 선택 상태는 diffable item의 정체성(hash/equality)에 안 들어있어서 스냅샷을 다시 적용할 필요 없이,
    // 화면에 보이는 셀을 직접 찾아서 표시만 바꿔주면 된다
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.toggleSelection(id: item.localIdentifier)
        (collectionView.cellForItem(at: indexPath) as? PhotoCell)?.setSelected(true)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.toggleSelection(id: item.localIdentifier)
        (collectionView.cellForItem(at: indexPath) as? PhotoCell)?.setSelected(false)
    }

    // true를 반환해야 길게 누른 채로 드래그해서 여러 셀을 한 번에 선택하는 제스처가 활성화된다
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        true
    }
}
