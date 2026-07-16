//
//  TravelPhotoPickerViewController.swift
//  Presentation
//
//  Created by sanghyeon on 7/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Combine
import Domain

/// 여행 앨범에 사진을 수동으로 추가하는 2단계 마법사의 한 화면. 타이틀은 항상 "사진 선택",
/// 다른 화면과 동일하게 NaviBarView(.leading)를 써서 왼쪽 버튼 옆에 붙인다.
/// direction이 .before면 "여행 기간 이전 사진"(취소/다음), .after면 "여행 기간 다음 사진"(취소/이전/추가)이 된다
final class TravelPhotoPickerViewController: UIViewController {

    // MARK: - Callbacks

    var onCancel: (() -> Void)?
    var onNext: (([PhotoInAlbum]) -> Void)?
    var onBack: (() -> Void)?
    var onFinish: (() -> Void)?
    /// 이미지를 탭해서 상세(뷰어)로 보여달라는 요청 — 앨범 상세와 동일하게 뷰어에서도 선택할 수 있다
    var onSelectPhoto: ((_ photoDetails: [PhotoDetail], _ index: Int, _ selectedIdentifiers: Set<String>) -> Void)?

    // MARK: - Properties

    private let viewModel: TravelPhotoPickerViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>!
    private var cancellables = Set<AnyCancellable>()
    private var isCommitting = false

    // MARK: - UI

    private let naviView = NaviBarView(type: .title(.leading))

    private let headerLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 15, weight: .semibold)
        lb.textColor = Theme.textPrimary
        return lb
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
        view.addSubview(naviView)
        view.addSubview(headerLabel)
        view.addSubview(collectionView)

        naviView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        headerLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(naviView.snp.bottom).offset(16)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupTopBar() {
        naviView.setTitle("사진 선택", font: .systemFont(ofSize: 17, weight: .semibold))
        headerLabel.text = viewModel.direction.headerText

        switch viewModel.direction {
        case .before:
            naviView.addButtons([LeftButton(type: .text("취소")), RightButton(type: .text("다음"))])
        case .after:
            naviView.addButtons([LeftButton(type: .text("취소")), RightButton(type: .text("이전")), RightButton(type: .text("추가"))])
        }

        naviView.publisher
            .sink { [weak self] type in
                guard let self, case .text(let text) = type else { return }
                switch text {
                case "취소": onCancel?()
                case "이전": onBack?()
                case "다음": onNext?(viewModel.accumulatedSelections)
                case "추가": addTapped()
                default: break
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func addTapped() {
        guard !isCommitting else { return }
        isCommitting = true
        Task {
            do {
                try await viewModel.commit()
                onFinish?()
            } catch {
                print("🐛 사진 추가 commit 실패:", error)
            }
            isCommitting = false
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
            // 길게 눌러서 드래그로 여러 개든 전부 didSelectItemAt/didDeselectItemAt으로 들어와 그리드
            // 선택은 그쪽에서 처리된다. onImageTap은 선택을 건드리지 않고 상세(뷰어)만 띄운다 —
            // 앨범 상세와 동일하게 두 경로가 각자 역할만 하므로 겹쳐도 문제없다
            cell.onImageTap = { [weak self] in
                guard let self,
                      let index = self.viewModel.photos.firstIndex(where: { $0.localIdentifier == cellViewModel.localIdentifier })
                else { return }
                self.onSelectPhoto?(self.viewModel.photoDetails, index, self.viewModel.selectedIds)
            }
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

    // 상세(뷰어)에서 선택 상태를 바꾸고 돌아왔을 때 호출 — 앨범 상세의 syncSelection과 동일한 패턴
    func syncSelection(_ identifiers: Set<String>) {
        viewModel.syncSelection(identifiers)
        collectionView.visibleCells.forEach { cell in
            guard let photoCell = cell as? PhotoCell,
                  let indexPath = collectionView.indexPath(for: photoCell),
                  let item = dataSource.itemIdentifier(for: indexPath) else { return }
            photoCell.setSelected(identifiers.contains(item.localIdentifier))
        }
    }

    func scrollToItem(id: String) {
        let items = dataSource.snapshot().itemIdentifiers(inSection: 0)
        guard let index = items.firstIndex(where: { $0.localIdentifier == id }) else { return }
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredVertically, animated: false)
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
