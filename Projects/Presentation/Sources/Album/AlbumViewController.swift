//
//  AlbumViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

final class AlbumViewController: BaseViewController {
    
    private let naviView: NaviBarView = NaviBarView(type: .title(.leading))
    
    private var collectionView: UICollectionView = {
        
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = Theme.background

        return collectionView
    }()
    
    private var emptyView: AlbumEmtpyView = AlbumEmtpyView()
    
    private var dataSource: UICollectionViewDiffableDataSource<AlbumSection, AlbumType>!
    
    private let viewModel: AlbumViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: AlbumViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setupBindings()
        
        self.viewModel.send(.appear)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        self.viewModel.send(.appear)
    }
    
    private func setupView() {
        
        naviView.setTitle("앨범",
                          color: Theme.textPrimary,
                          font: .systemFont(ofSize: 32, weight: .bold))
        naviView.setMessage("사진이 개 앨범으로 정리되었어요",
                            color: Theme.textPrimary,
                            font: .systemFont(ofSize: 14, weight: .regular))
        
        collectionView.setCollectionViewLayout(makeLayout(), animated: false)
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 80, right: 0)
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        view.addSubview(naviView)
        view.addSubview(emptyView)
        
        self.configureDataSource()
        
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(self.view)
        }
        
        naviView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.view)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(naviView.snp.bottom)
            make.bottom.leading.trailing.equalTo(self.view)
        }
    }
    
    private func setupBindings() {
        
        naviView.publisher
            .sink { [weak self] type in
                guard let self else {return}
                switch type {
                case .analysis:
                    self.viewModel.send(.analysis)
                case .reset:
                    self.viewModel.send(.clear)
                default: break
                }
            }
            .store(in: &cancellables)
        
        emptyView.publisher
            .sink { [weak self] _ in
                self?.viewModel.send(.analysis)
            }
            .store(in: &cancellables)
        
        let output = self.viewModel.transform()
        output.sections
            .sink { [weak self] data in
                guard let self else { return }
                
                if data.isEmpty {
                    self.emptyView.isHidden = false
                    self.naviView.isHidden = true
                } else {
                    self.emptyView.isHidden = true
                    self.naviView.isHidden = false
                    self.naviView.setMessage(
                        "\(data.totalCount)개 앨범으로 정리되었어요",
                        color: Theme.textPrimary,
                        font: .systemFont(ofSize: 14, weight: .regular))
                }
                self.applySnapshot(data: data)
            }
            .store(in: &cancellables)
        
        output.permission
            .sink { permission in
                print("!!", permission)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Compositional Layout
    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let section = self?.dataSource.snapshot().sectionIdentifiers[sectionIndex] else { return nil }
            switch section {
            case .date:     return self?.makeDateSection()
            case .travel:     return self?.makeTravelSection()
            case .location:  return self?.makeLocationSection(environment: environment)
            case .category: return self?.makeCategorySection()
            case .face:     return self?.makeFaceSection()
            case .similar:  return self?.makeSimilarSection()
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
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    /// 여행앨범: 세로 리스트, 높이 100pt
    private func makeTravelSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(0.5)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.85), // 0.85로 오른쪽에 다음 셀 살짝 보이게
            heightDimension: .absolute(212)         // 100 * 2 + spacing 12
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(12)

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    /// 장소: 첫 아이템 full-width large, 나머지 2컬럼 small
    private func makeLocationSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let smallHeight = 120.0
        let totalWidth = environment.container.effectiveContentSize.width - 40  // 좌우 inset 20씩

        // large item (full width)
        let largeItemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(totalWidth),
            heightDimension: .absolute(88)
        )
        let largeItem = NSCollectionLayoutItem(layoutSize: largeItemSize)

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
            heightDimension: .absolute(88 + 10 + smallHeight)   // 88 + 10 + 110
        )
        let outerGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: outerGroupSize,
            subitems: [largeItem, smallGroup]
        )
        outerGroup.interItemSpacing = .fixed(10)

        let section = NSCollectionLayoutSection(group: outerGroup)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        section.boundarySupplementaryItems = [makeHeader()]
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
        section.boundarySupplementaryItems = [makeHeader()]
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
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }
    
    private func makeSimilarSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(88),
            heightDimension: .absolute(88)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(88),
            heightDimension: .absolute(88)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    private func makeHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
}

extension AlbumViewController {
    private func configureDataSource() {
    
        let timeRegistration = UICollectionView.CellRegistration<DateAlbumCell, DateAlbumCellViewModel> { cell, _, vm in
            cell.configure(with: vm)
        }

        let tripRegistration = UICollectionView.CellRegistration<TravelAlbumCell, TravelAlbumCellViewModel> { cell, _, vm in
            cell.configure(with: vm)
        }

        let addressRegistration = UICollectionView.CellRegistration<LocationAlbumCell, LocationAlbumCellViewModel> { cell, indexPath, vm in
            let style: AddressCellStyle = (indexPath.item == 0) ? .large : .small
            cell.configure(with: vm, style: style)
        }

        let categoryRegistration = UICollectionView.CellRegistration<CategoryAlbumCell, CategoryAlbumCellViewModel> { [weak self] cell, indexPath, vm in
            guard let self else { return }
            let items = self.dataSource.snapshot().itemIdentifiers(inSection: .category)
            cell.isFirst = (indexPath.item == 0)
            cell.isLast  = (indexPath.item == items.count - 1)
            cell.configure(with: vm)
        }

        let faceRegistration = UICollectionView.CellRegistration<FaceAlbumCell, FaceCellViewModel> { cell, _, vm in
            cell.configure(with: vm)
        }
        
        let similarRegistration = UICollectionView.CellRegistration<SimilarAlbumCell, SimilarAlbumCellViewModel> { cell, _, vm in
            cell.configure(with: vm)
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<AlbumSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
//            guard let section = AlbumSection(rawValue: indexPath.section) else { return }
//            header.configure(title: section.title)
            guard let self = self else { return }
                
            let snapshot = self.dataSource.snapshot()
            let section = snapshot.sectionIdentifiers[indexPath.section]
            let itemCount = snapshot.numberOfItems(inSection: section)
            
//            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            header.configure(section, itemCount: itemCount)
            header.onMoreTapped = { self.viewModel.send(.more(section.type)) }
        }
        
        dataSource = UICollectionViewDiffableDataSource<AlbumSection, AlbumType>(
            collectionView: collectionView
        ) { /*[weak self]*/ collectionView, indexPath, item in
//            guard let self else { return UICollectionViewCell() }
            switch item {
            case .date(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: timeRegistration,
                    for: indexPath,
                    item: vm)
            case .travel(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: tripRegistration,
                    for: indexPath,
                    item: vm)
            case .location(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: addressRegistration,
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
            case .similar(let vm):
                return collectionView.dequeueConfiguredReusableCell(
                    using: similarRegistration,
                    for: indexPath,
                    item: vm)
            }
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    private func applySnapshot(data: AlbumSectionsData) {
        var snapshot = NSDiffableDataSourceSnapshot<AlbumSection, AlbumType>()
        
        snapshot.appendSections(data.sections)
        data.sections.forEach { snapshot.appendItems(data.items[$0] ?? [], toSection: $0) }

        dataSource.apply(snapshot, animatingDifferences: true){
            // apply 완료 후 layout 갱신
            self.collectionView.setCollectionViewLayout(self.makeLayout(), animated: false)
        }
    }
}

extension AlbumViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let albumType = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.send(.selectItem(albumType.album))
    }

}

extension AlbumViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}
