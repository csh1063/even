//
//  AlbumListViewController.swift
//  Presentation
//
//  Created by sanghyeon on 6/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Domain

final class AlbumListViewController: BaseViewController {

    private let naviView = NaviBarView()

    private var collectionView: UICollectionView = {

        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = Theme.background

        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Int, AlbumType>!

    private let actionBar = AlbumSelectionActionBar()

    private let viewModel: AlbumListViewModel

    private var cancellables = Set<AnyCancellable>()

    private var isSelectionMode = false {
        didSet { updateSelectionUI() }
    }
    private var selectedAlbumIds: Set<UUID> = []

    init(viewModel: AlbumListViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
        self.binding()

        self.viewModel.send(.appear)
    }

    private func setupView() {

        self.naviView.setTitle("여행")
        self.naviView.addButtons([LeftButton(type: .back), RightButton(type: .select)])

        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 80, right: 0)
        collectionView.delegate = self
        collectionView.setCollectionViewLayout(makeLayout(type: viewModel.from), animated: false)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)

        self.view.addSubview(naviView)
        self.view.addSubview(collectionView)
        self.view.addSubview(actionBar)

        self.configureDataSource()

        naviView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
        }

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.naviView.snp.bottom)
            make.bottom.equalToSuperview()
        }

        actionBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(88)
        }

        actionBar.isHidden = true
        actionBar.setSelectedCount(0)
    }

    private func binding() {
        let output = viewModel.transform()
        output.albumData.sink { data in
            self.applySnapshot(data: data)
        }
        .store(in: &cancellables)

        naviView.publisher.sink { [weak self] type in
            guard let self else { return }
            switch type {
            case .back:
                self.viewModel.send(.dismiss)
            case .select:
                self.isSelectionMode = true
            case .cancel:
                self.isSelectionMode = false
            default: break
            }
        }
        .store(in: &cancellables)

        actionBar.deletePublisher
            .sink { [weak self] in
                guard let self else { return }
                let albums = self.selectedAlbumIds.compactMap { id in
                    self.dataSource.snapshot().itemIdentifiers.first { $0.album.id == id }?.album
                }
                guard !albums.isEmpty else { return }
                self.viewModel.send(.confirmDeleteAlbums(albums))
            }
            .store(in: &cancellables)
    }

    // MARK: - Selection Mode

    private func updateSelectionUI() {
        actionBar.isHidden = !isSelectionMode
        if !isSelectionMode {
            selectedAlbumIds.removeAll()
        }
        actionBar.setSelectedCount(selectedAlbumIds.count)
        reloadVisibleSelectionOverlays()

        // 앨범 상세와 동일하게, 선택 모드일 땐 "선택" 버튼 자리를 "X"(취소)로 바꾼다
        naviView.addButtons(
            isSelectionMode
                ? [LeftButton(type: .back), RightButton(type: .cancel)]
                : [LeftButton(type: .back), RightButton(type: .select)]
        )
    }

    private func reloadVisibleSelectionOverlays() {
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let album = dataSource.itemIdentifier(for: indexPath)?.album else { continue }
            cell.applySelectionOverlay(isSelectionMode: isSelectionMode, isSelected: selectedAlbumIds.contains(album.id))
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, !isSelectionMode else { return }
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let album = dataSource.itemIdentifier(for: indexPath)?.album else { return }
        viewModel.send(.showAlbumMenu(album))
    }

    private func applySelectionOverlay(to cell: UICollectionViewCell, album: Album) {
        cell.applySelectionOverlay(isSelectionMode: isSelectionMode, isSelected: selectedAlbumIds.contains(album.id))
    }

    // MARK: - Compositional Layout
    private func makeLayout(type: String) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] _, environment in
            switch type {
            case "date":     return self?.makeDateSection()
            case "travel":     return self?.makeTravelSection()
            case "location":  return self?.makeLocationSection(environment: environment)
            case "category": return self?.makeCategorySection()
            case "face":     return self?.makeFaceSection()
            case "similar": return self?.makeSimilarSection()
            default: return self?.makeTravelSection()
            }
        }
    }

    private func makeDateSection() -> NSCollectionLayoutSection {
        let height = 120.0
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(140),
            heightDimension: .absolute(height)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(140),
            heightDimension: .absolute(height)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
//        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        return section
    }

    /// 여행앨범: 세로 리스트, 높이 100pt
    private func makeTravelSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0), // 0.85로 오른쪽에 다음 셀 살짝 보이게
            heightDimension: .absolute(100)         // 100 * 2 + spacing 12
//            heightDimension: .fractionalHeight(1.0)         // 100 * 2 + spacing 12
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(12)

        let section = NSCollectionLayoutSection(group: group)
//        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        return section
    }

    /// 장소: 첫 아이템 full-width large, 나머지 2컬럼 small
    private func makeLocationSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let smallHeight = 120.0
        let totalWidth = environment.container.effectiveContentSize.width - 40  // 좌우 inset 20씩

        // large item (full width)
//        let largeItemSize = NSCollectionLayoutSize(
//            widthDimension: .absolute(totalWidth),
//            heightDimension: .absolute(88)
//        )
//        let largeItem = NSCollectionLayoutItem(layoutSize: largeItemSize)

        // small item (half width)
        let smallWidth = (totalWidth - 10) / 2
        let smallItemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(smallWidth),
            heightDimension: .absolute(smallHeight)
        )
        let smallItem = NSCollectionLayoutItem(layoutSize: smallItemSize)

        // small 2개 가로 그룹
        let smallGroupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(totalWidth),
            heightDimension: .absolute(smallHeight)
        )
        let smallGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: smallGroupSize,
            subitems: [smallItem, smallItem]
        )
        smallGroup.interItemSpacing = .fixed(10)

        // large + small 묶는 vertical 그룹
        let outerGroupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(totalWidth),
            heightDimension: .absolute(smallHeight)   // 88 + 10 + 110
        )
        let outerGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: outerGroupSize,
            subitems: [smallGroup]
//            subitems: [largeItem, smallGroup]
        )
        outerGroup.interItemSpacing = .fixed(10)

        let section = NSCollectionLayoutSection(group: outerGroup)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        return section
    }

    /// 카테고리: 전체 너비 리스트 (자동 높이)
    private func makeCategorySection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(64)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(64)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        return section
    }

    /// 인물: 수평 스크롤 아바타
    private func makeFaceSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(80),
            heightDimension: .absolute(96)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(80),
            heightDimension: .absolute(96)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        return section
    }
    private func makeSimilarSection() -> NSCollectionLayoutSection {

        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = (screenWidth - 32) / 4  // leading+trailing inset 32, 아이템간 간격 24

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(itemWidth),
            heightDimension: .absolute(itemWidth)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(itemWidth)
        )

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
//        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 4
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 28, trailing: 16)
        return section
    }
}

extension AlbumListViewController {
    private func configureDataSource() {

        let dateRegistration = UICollectionView.CellRegistration<DateAlbumCell, DateAlbumCellViewModel> { [weak self] cell, _, vm in
            cell.configure(with: vm)
            self?.applySelectionOverlay(to: cell, album: vm.album)
        }

        let travelRegistration = UICollectionView.CellRegistration<TravelAlbumCell, TravelAlbumCellViewModel> { [weak self] cell, _, vm in
            cell.configure(with: vm)
            self?.applySelectionOverlay(to: cell, album: vm.album)
        }

        let locationRegistration = UICollectionView.CellRegistration<LocationAlbumCell, LocationAlbumCellViewModel> { [weak self] cell, _, vm in
//            let style: AddressCellStyle = (indexPath.item == 0) ? .large : .small
            cell.configure(with: vm, style: .small)
            self?.applySelectionOverlay(to: cell, album: vm.album)
        }

        let categoryRegistration = UICollectionView.CellRegistration<CategoryAlbumCell, CategoryAlbumCellViewModel> { [weak self] cell, _, vm in
//            let items = self.dataSource.snapshot().itemIdentifiers(inSection: .category)
//            cell.isFirst = (indexPath.item == 0)
//            cell.isLast  = (indexPath.item == items.count - 1)
            cell.configure(with: vm)
            self?.applySelectionOverlay(to: cell, album: vm.album)
        }

        let faceRegistration = UICollectionView.CellRegistration<FaceAlbumCell, FaceAlbumCellViewModel> { [weak self] cell, _, vm in
            cell.configure(with: vm)
            self?.applySelectionOverlay(to: cell, album: vm.album)
        }

        let animalRegistration = UICollectionView.CellRegistration<AnimalAlbumCell, AnimalAlbumCellViewModel> { [weak self] cell, _, vm in
            cell.configure(with: vm)
            self?.applySelectionOverlay(to: cell, album: vm.album)
        }

        let similarRegistration = UICollectionView.CellRegistration<SimilarAlbumCell, SimilarAlbumCellViewModel> { [weak self] cell, _, vm in
            cell.configure(with: vm, hasCover: true)
            self?.applySelectionOverlay(to: cell, album: vm.album)
        }

        dataSource = UICollectionViewDiffableDataSource<Int, AlbumType>(
            collectionView: collectionView
        ) { /*[weak self]*/ collectionView, indexPath, item in
//            guard let self else { return UICollectionViewCell() }
            switch item {
            case .date(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: dateRegistration,
                    for: indexPath,
                    item: vm)
            case .travel(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: travelRegistration,
                    for: indexPath,
                    item: vm)
            case .location(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: locationRegistration,
                    for: indexPath,
                    item: vm)
            case .category(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: categoryRegistration,
                    for: indexPath,
                    item: vm)
            case .face(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: faceRegistration,
                    for: indexPath,
                    item: vm)
            case .animal(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: animalRegistration,
                    for: indexPath,
                    item: vm)
            case .similar(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: similarRegistration,
                    for: indexPath,
                    item: vm)
            }
        }
    }

    private func applySnapshot(data: AlbumListData) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, AlbumType>()

//        snapshot.appendSections(data.sections)
        snapshot.appendSections([0])  // 섹션 먼저
        snapshot.appendItems(data.albums)

        // 레이아웃은 이 화면 진입 시 한 번만 정해지면 된다(타입이 인스턴스 생애주기 동안 안 바뀜) —
        // 매번 setCollectionViewLayout으로 새 레이아웃을 만들면 가로 캐러셀/세로 스크롤 위치가 리셋된다
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension AlbumListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let albumType = dataSource.itemIdentifier(for: indexPath) else { return }

        guard isSelectionMode else {
            viewModel.send(.selectItem(albumType.album))
            return
        }

        let id = albumType.album.id
        if selectedAlbumIds.contains(id) {
            selectedAlbumIds.remove(id)
        } else {
            selectedAlbumIds.insert(id)
        }
        actionBar.setSelectedCount(selectedAlbumIds.count)
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.applySelectionOverlay(isSelectionMode: true, isSelected: selectedAlbumIds.contains(id))
        }
    }

}
