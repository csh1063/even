//
//  AlbumDetailViewController.swift
//  Presentation
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//

import UIKit
import SnapKit
import Combine
import Domain

enum AlbumDetailPageMode {
    case list
    case select
    case onlySelect
}

final class AlbumDetailViewController: BaseViewController {

    // MARK: - UI

    private var naviView = NaviBarView(type: .title(.leading))

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
        cv.isScrollEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.contentInset = UIEdgeInsets(top: 8, left: space, bottom: 80, right: space)
        cv.backgroundColor = .clear
        return cv
    }()

    private let bottomBar: UIView = {
        let v = UIView()
        v.backgroundColor = Theme.background
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: -2)
        v.layer.shadowRadius = 8
        return v
    }()

    private let deleteButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "trash")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = Theme.negative
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        return btn
    }()

    private let selectedCountLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = Theme.textSecondary
        lb.font = .systemFont(ofSize: 14, weight: .regular)
        lb.text = "0개 선택"
        return lb
    }()

    // MARK: - Properties

    private var dataSource: UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>!
    private let viewModel: AlbumDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private var pageMode: AlbumDetailPageMode = .list {
        didSet { updateModeUI() }
    }
    private var isSelectionMode: Bool { pageMode != .list }
    private(set) var selectedIdentifiers: Set<String> = []

    // MARK: - Init

    init(viewModel: AlbumDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupBindings()
        viewModel.send(.appear)
    }

    // MARK: - Setup

    private func setupView() {
        naviView.addButtons([LeftButton(type: .back), RightButton(type: .more)])
        configureDataSource()
        collectionView.delegate = self

        view.addSubview(naviView)
        view.addSubview(collectionView)
        view.addSubview(bottomBar)
        bottomBar.addSubview(selectedCountLabel)
        bottomBar.addSubview(deleteButton)

        naviView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(naviView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(88)
        }
        selectedCountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview().offset(-10)
        }
        deleteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview().offset(-10)
            make.height.equalTo(44)
            make.width.equalTo(44)
        }

        bottomBar.isHidden = true
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    private func setupBindings() {
        let output = viewModel.transform()

        output.name
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in self?.naviView.setTitle(name) }
            .store(in: &cancellables)

        output.photos
            .receive(on: DispatchQueue.main)
            .map { [weak self] photos -> [PhotoCellItemViewModel] in
                guard let self else { return [] }
                return photos.map { PhotoCellItemViewModel(localIdentifier: $0.localIdentifier, imageLoader: self.viewModel) }
            }
            .sink { [weak self] photos in self?.applySnapshot(with: photos) }
            .store(in: &cancellables)

        output.selectionMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                guard let self, pageMode == .list else { return }
                enterMode(mode)
            }
            .store(in: &cancellables)

        bindNaviActions()
    }

    private func bindNaviActions() {
        naviView.publisher
            .sink { [weak self] type in
                guard let self else { return }
                switch type {
                case .back:   viewModel.send(.dismiss)
                case .more:   viewModel.send(.more)
                case .cancel: exitSelectionMode()
                default: break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Mode

    func enterMode(_ mode: AlbumDetailPageMode) {
        guard mode != .list else { return }
        pageMode = mode
        collectionView.isEditing = true
    }

    func exitSelectionMode() {
        selectedIdentifiers.removeAll()
        pageMode = .list
        collectionView.isEditing = false
        updateSelectedCount()
    }

    // viewer에서 선택 상태 동기화
    func syncSelection(_ identifiers: Set<String>) {
        selectedIdentifiers = identifiers
        updateSelectedCount()
        collectionView.visibleCells.forEach { cell in
            guard let photoCell = cell as? PhotoCell,
                  let indexPath = collectionView.indexPath(for: photoCell),
                  let item = dataSource.itemIdentifier(for: indexPath) else { return }
            photoCell.setSelected(selectedIdentifiers.contains(item.localIdentifier))
        }
    }

    private func updateModeUI() {
        bottomBar.isHidden = !isSelectionMode

        switch pageMode {
        case .list:
            collectionView.allowsMultipleSelection = false
            collectionView.allowsMultipleSelectionDuringEditing = false
            naviView.addButtons([LeftButton(type: .back), RightButton(type: .more)])
        case .select:
            collectionView.allowsMultipleSelection = true
            collectionView.allowsMultipleSelectionDuringEditing = true
            naviView.addButtons([LeftButton(type: .back), RightButton(type: .cancel)])
        case .onlySelect:
            collectionView.allowsMultipleSelection = true
            collectionView.allowsMultipleSelectionDuringEditing = true
            naviView.addButtons([LeftButton(type: .back)])
        }

        bindNaviActions()

        collectionView.visibleCells.forEach { cell in
            guard let photoCell = cell as? PhotoCell else { return }
            photoCell.setSelectionMode(isSelectionMode)
        }
    }

    private func updateSelectedCount() {
        let count = selectedIdentifiers.count
        selectedCountLabel.text = "\(count)개 선택"
        deleteButton.isEnabled = count > 0
        deleteButton.alpha = count > 0 ? 1.0 : 0.4
    }

    // MARK: - Actions

    @objc private func deleteButtonTapped() {
        guard !selectedIdentifiers.isEmpty else { return }
        viewModel.send(.deleteSelected(ids: Array(selectedIdentifiers)))
    }

    // MARK: - Scroll

    func scrollToItem(id: String) {
        let snapshot = dataSource.snapshot()
        for (sectionIndex, section) in snapshot.sectionIdentifiers.enumerated() {
            let items = snapshot.itemIdentifiers(inSection: section)
            if let itemIndex = items.firstIndex(where: { $0.localIdentifier == id }) {
                collectionView.scrollToItem(at: IndexPath(item: itemIndex, section: sectionIndex), at: .centeredVertically, animated: false)
                return
            }
        }
    }
}

// MARK: - DataSource

extension AlbumDetailViewController {
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PhotoCell, PhotoCellItemViewModel> { [weak self] cell, indexPath, cellViewModel in
            guard let self else { return }
            cell.configure(with: cellViewModel, index: indexPath.row)
            cell.setSelectionMode(isSelectionMode)
            cell.setSelected(selectedIdentifiers.contains(cellViewModel.localIdentifier))

//            // 셀 탭 → viewer 열기
//            cell.cellTapPublisher
//                .sink { [weak self] in
//                    self?.viewModel.send(.selectItem(id: cellViewModel.localIdentifier, inSelectionMode: self?.isSelectionMode ?? false))
//                }
//                .store(in: &cancellables)

            cell.onImageTap = { [weak self] in
                self?.viewModel.send(.selectItem(id: cellViewModel.localIdentifier, inSelectionMode: self?.isSelectionMode ?? false))
            }
        }

        dataSource = UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>(collectionView: collectionView) { cv, indexPath, vm in
            cv.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: vm)
        }
    }

    private func applySnapshot(with photos: [PhotoCellItemViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PhotoCellItemViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(photos)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDelegate

extension AlbumDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell else { return }

        selectedIdentifiers.insert(item.localIdentifier)
        cell.setSelected(true)
        updateSelectedCount()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell else { return }

        selectedIdentifiers.remove(item.localIdentifier)
        cell.setSelected(false)
        updateSelectedCount()
    }

    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        if pageMode == .list { enterMode(.select) }
    }
}

// import Foundation
// import UIKit
// import Combine
// import Domain
//
// final class AlbumDetailViewController: BaseViewController {
//
//    // MARK: - UI
//
//    private var naviView: NaviBarView = NaviBarView(type: .title(.leading))
//
//    private lazy var collectionView: UICollectionView = {
//        let space: CGFloat = 2
//        let count: CGFloat = 3
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .vertical
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        layout.minimumLineSpacing = space
//        layout.minimumInteritemSpacing = space
//        let width = (UIScreen.main.bounds.width - (space * (count + 1))) / count
//        layout.itemSize = CGSize(width: width, height: width)
//        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        cv.isScrollEnabled = true
//        cv.showsVerticalScrollIndicator = false
//        cv.contentInset = UIEdgeInsets(top: 8, left: space, bottom: 80, right: space)
//        cv.backgroundColor = .clear
////        cv.allowsMultipleSelection = true
////        cv.allowsMultipleSelection = true
////        cv.allowsMultipleSelectionDuringEditing = true
//        return cv
//    }()
//
//    // 하단 삭제 바
//    private let bottomBar: UIView = {
//        let v = UIView()
//        v.backgroundColor = Theme.background
//        v.layer.shadowColor = UIColor.black.cgColor
//        v.layer.shadowOpacity = 0.08
//        v.layer.shadowOffset = CGSize(width: 0, height: -2)
//        v.layer.shadowRadius = 8
//        return v
//    }()
//
//    private let deleteButton: UIButton = {
//        var config = UIButton.Configuration.filled()
//        config.title = "삭제"
//        config.baseForegroundColor = .white
//        config.baseBackgroundColor = Theme.negative
//        config.cornerStyle = .medium
//        let btn = UIButton(configuration: config)
//        return btn
//    }()
//
//    private let selectedCountLabel: UILabel = {
//        let lb = UILabel()
//        lb.textColor = Theme.textSecondary
//        lb.font = .systemFont(ofSize: 14, weight: .regular)
//        lb.text = "0개 선택"
//        return lb
//    }()
//
//    // MARK: - Properties
//
//    private var dataSource: UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>!
//    private let viewModel: AlbumDetailViewModel
//    private var cancellables = Set<AnyCancellable>()
//
//    // 선택 모드
//    private var selectionMode: AlbumDetailPageMode = .list {
//        didSet { updateSelectionModeUI() }
//    }
//    private var isSelectionMode: Bool {
//        return selectionMode != .list
//    }
//    private var selectedIdentifiers: Set<String> = []
//
//    // 롱탭 드래그
//    private var isDragging = false
//    private var dragStarted = false
//    private var dragSelecting: Bool = true
//
//    // MARK: - Init
//
//    init(viewModel: AlbumDetailViewModel) {
//        self.viewModel = viewModel
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required public init?(coder: NSCoder) {
//        fatalError(Self.fatalMessage)
//    }
//
//    // MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupView()
//        setupGestures()
//        setupBindings()
//        
//        self.viewModel.send(.appear)
//    }
//
//    // MARK: - Setup
//
//    private func setupView() {
//        naviView.addButtons([LeftButton(type: .back),
//                             RightButton(type: .more)])
//
//        configureDataSource()
//        collectionView.delegate = self
//
//        view.addSubview(naviView)
//        view.addSubview(collectionView)
//        view.addSubview(bottomBar)
//        bottomBar.addSubview(selectedCountLabel)
//        bottomBar.addSubview(deleteButton)
//
//        naviView.snp.makeConstraints { make in
//            make.top.equalToSuperview()
//            make.leading.trailing.equalToSuperview()
//        }
//        collectionView.snp.makeConstraints { make in
//            make.top.equalTo(naviView.snp.bottom)
//            make.leading.trailing.bottom.equalToSuperview()
//        }
//        bottomBar.snp.makeConstraints { make in
//            make.leading.trailing.bottom.equalToSuperview()
//            make.height.equalTo(88)
//        }
//        selectedCountLabel.snp.makeConstraints { make in
//            make.leading.equalToSuperview().offset(20)
//            make.centerY.equalToSuperview().offset(-10)
//        }
//        deleteButton.snp.makeConstraints { make in
//            make.trailing.equalToSuperview().inset(20)
//            make.centerY.equalToSuperview().offset(-10)
//            make.height.equalTo(44)
//            make.width.equalTo(80)
//        }
//
//        bottomBar.isHidden = true
//
//        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
//    }
//
//    private func setupGestures() {
////        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
////        longPress.minimumPressDuration = 0.4
////        collectionView.addGestureRecognizer(longPress)
//    }
//    
//    private func setupBindings() {
//        let output = viewModel.transform()
//
//        output.name
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] name in
//                self?.naviView.setTitle(name)
//            }
//            .store(in: &cancellables)
//
//        output.photos
//            .receive(on: DispatchQueue.main)
//            .map { [weak self] photos -> [PhotoCellItemViewModel] in
//                guard let self else { return [] }
//                return photos.map {
//                    PhotoCellItemViewModel(localIdentifier: $0.localIdentifier, imageLoader: self.viewModel)
//                }
//            }
//            .sink { [weak self] photos in
//                self?.applySnapshot(with: photos)
//            }
//            .store(in: &cancellables)
//
//        output.selectionMode
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] mode in
//                guard let self else { return }
////                if isSelection && !isSelectionMode {
////                    enterSelectionMode()
////                }
//                
//                if !isSelectionMode {
//                    enterSelectionMode(mode)
//                }
//            }
//            .store(in: &cancellables)
//        
//        bindingNavi()
//    }
//    
//    private func bindingNavi() {
//        naviView.publisher
//            .sink { [weak self] type in
//                guard let self else { return }
//                switch type {
//                case .back:
////                    if isSelectionMode {
////                        exitSelectionMode()
////                    } else {
//                        viewModel.send(.dismiss)
////                    }
//                case .more:
//                    viewModel.send(.more)
//                case .cancel:
//                    exitSelectionMode()
//                default: break
//                }
//            }
//            .store(in: &cancellables)
//    }
//
//    // MARK: - Selection Mode
//
//    func enterSelectionMode(_ mode: AlbumDetailPageMode) {
//        selectionMode = mode
//        collectionView.isEditing = true
//    }
//
//    func exitSelectionMode() {
//        selectionMode = .list
//        collectionView.isEditing = false
//        selectedIdentifiers.removeAll()
//        collectionView.indexPathsForSelectedItems?.forEach {
//            collectionView.deselectItem(at: $0, animated: false)
//        }
//        updateSelectedCount()
//    }
//
//    private func updateSelectionModeUI() {
//        bottomBar.isHidden = !isSelectionMode
//
//        switch selectionMode {
//        case .list:
//            collectionView.allowsMultipleSelection = false
//            collectionView.allowsMultipleSelectionDuringEditing = false
//            naviView.addButtons([LeftButton(type: .back),
//                                 RightButton(type: .more)])
//        case .select:
//            collectionView.allowsMultipleSelection = true
//            collectionView.allowsMultipleSelectionDuringEditing = true
//            naviView.addButtons([LeftButton(type: .back),
//                                 RightButton(type: .cancel)])
//        case .onlySelect:
//            collectionView.allowsMultipleSelection = true
//            collectionView.allowsMultipleSelectionDuringEditing = true
//            naviView.addButtons([LeftButton(type: .back)])
//        }
//        
//        bindingNavi()
//        collectionView.visibleCells.forEach { cell in
//            guard let photoCell = cell as? PhotoCell else { return }
//            photoCell.setSelectionMode(isSelectionMode)
//        }
//    }
//
//    private func updateSelectedCount() {
//        let count = selectedIdentifiers.count
//        selectedCountLabel.text = "\(count)개 선택"
//        deleteButton.isEnabled = count > 0
//        deleteButton.alpha = count > 0 ? 1.0 : 0.4
//    }
//
//    // MARK: - Actions
//
//    @objc private func deleteButtonTapped() {
//        let count = selectedIdentifiers.count
//        guard count > 0 else { return }
//        viewModel.send(.deleteSelected(ids: Array(selectedIdentifiers)))
//    }
//
//    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
//        let point = gesture.location(in: collectionView)
//
//        switch gesture.state {
//        case .began:
//            guard let indexPath = collectionView.indexPathForItem(at: point),
//                  let item = dataSource.itemIdentifier(for: indexPath) else { return }
//            if !isSelectionMode { enterSelectionMode(.select) }
//            dragStarted = true
//            isDragging = true
//            dragSelecting = !selectedIdentifiers.contains(item.localIdentifier)  // 첫 아이템 상태 기준
//            toggleSelection(for: item, at: indexPath)
//
//        case .changed:
//            guard isDragging,
//                  let indexPath = collectionView.indexPathForItem(at: point),
//                  let item = dataSource.itemIdentifier(for: indexPath) else { return }
//            // dragSelecting 방향에 맞는 아이템만 처리
//            let isSelected = selectedIdentifiers.contains(item.localIdentifier)
//            if dragSelecting && !isSelected {
//                toggleSelection(for: item, at: indexPath)
//            } else if !dragSelecting && isSelected {
//                toggleSelection(for: item, at: indexPath)
//            }
//
//
//        case .ended, .cancelled, .failed:
//            isDragging = false
//            dragStarted = false
//
//        default: break
//        }
//    }
//
//    private func toggleSelection(for item: PhotoCellItemViewModel, at indexPath: IndexPath) {
//        if selectedIdentifiers.contains(item.localIdentifier) {
//            selectedIdentifiers.remove(item.localIdentifier)
//            collectionView.deselectItem(at: indexPath, animated: false)
//            if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
//                cell.setSelected(false)
//            }
//        } else {
//            selectedIdentifiers.insert(item.localIdentifier)
//            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//            if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
//                cell.setSelected(true)
//            }
//        }
//        updateSelectedCount()
//    }
//
//    // MARK: - Scroll
//
//    func scrollToItem(id: String) {
//        let snapshot = dataSource.snapshot()
//        for (sectionIndex, section) in snapshot.sectionIdentifiers.enumerated() {
//            let items = snapshot.itemIdentifiers(inSection: section)
//            if let itemIndex = items.firstIndex(where: { $0.localIdentifier == id }) {
//                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
//                collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
//                return
//            }
//        }
//    }
// }
//
//// MARK: - DataSource
//
// extension AlbumDetailViewController {
//    private func configureDataSource() {
//        let cellRegistration = UICollectionView.CellRegistration<PhotoCell, PhotoCellItemViewModel> { [weak self] cell, indexPath, cellViewModel in
//            guard let self else { return }
//            cell.configure(with: cellViewModel, index: indexPath.row)
//            cell.setSelectionMode(isSelectionMode)
//            cell.setSelected(selectedIdentifiers.contains(cellViewModel.localIdentifier))
//        }
//
//        dataSource = UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>(collectionView: collectionView) {
//            collectionView, indexPath, cellViewModel in
//            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: cellViewModel)
//        }
//    }
//
//    private func applySnapshot(with photos: [PhotoCellItemViewModel]) {
//        var snapshot = NSDiffableDataSourceSnapshot<Int, PhotoCellItemViewModel>()
//        snapshot.appendSections([0])
//        snapshot.appendItems(photos)
//        dataSource.apply(snapshot, animatingDifferences: true)
//    }
// }
//
//// MARK: - UICollectionViewDelegate
//
// extension AlbumDetailViewController: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
//        if isSelectionMode {
//            selectedIdentifiers.insert(item.localIdentifier)
//            if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
//                cell.setSelected(true)
//            }
//            updateSelectedCount()
//        } else {
//            viewModel.send(.selectItem(id: item.localIdentifier))
//        }
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        guard isSelectionMode,
//              let item = dataSource.itemIdentifier(for: indexPath) else { return }
//        selectedIdentifiers.remove(item.localIdentifier)
//        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
//            cell.setSelected(false)
//        }
//        updateSelectedCount()
//    }
//
//    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
//        return self.isSelectionMode
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
//        if !isSelectionMode { enterSelectionMode(.select) }
//    }
// }
