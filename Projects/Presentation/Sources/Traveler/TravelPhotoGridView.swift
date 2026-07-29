//
//  TravelPhotoGridView.swift
//  Presentation
//
//  Created by sanghyeon on 7/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import SnapKit
import Domain

/// "사진 추가" 화면에서 이전/이후 한 방향의 사진 그리드 — 페이징 스크롤뷰에 나란히 두 개(이전용/이후용)
/// 놓고 쓴다. 그리드 자체(콜렉션뷰/선택/페이지네이션)만 담당하고, 방향 전환이나 최종 "추가"는 상위 화면이 맡는다
final class TravelPhotoGridView: UIView {

    /// 이미지를 탭해서 상세(뷰어)로 보여달라는 요청 — 앨범 상세와 동일하게 뷰어에서도 선택할 수 있다
    var onSelectPhoto: ((_ photoDetails: [PhotoDetail], _ index: Int, _ selectedIdentifiers: Set<String>) -> Void)?

    private let viewModel: TravelPhotoPickerViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>!

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

    init(viewModel: TravelPhotoPickerViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        configureDataSource()

        viewModel.onPhotosUpdated = { [weak self] in self?.applySnapshot() }
        Task { await viewModel.loadFirstPageIfNeeded() }
    }

    required init?(coder: NSCoder) {
        fatalError("TravelPhotoGridView does not support NSCoding.")
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

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PhotoCell, PhotoCellItemViewModel> { [weak self] cell, indexPath, cellViewModel in
            guard let self else { return }
            cell.configure(with: cellViewModel, index: indexPath.row)
            cell.setSelectionMode(true)
            cell.setSelected(viewModel.selectedIds.contains(cellViewModel.localIdentifier))
            // collectionView가 isEditing + allowsMultipleSelectionDuringEditing 상태라, 탭 한 번이든
            // 길게 눌러서 드래그로 여러 개든 전부 didSelectItemAt/didDeselectItemAt으로 들어와 그리드
            // 선택은 그쪽에서 처리된다. onImageTap은 선택을 건드리지 않고 상세(뷰어)만 띄운다
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
}

extension TravelPhotoGridView: UICollectionViewDelegate {
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
