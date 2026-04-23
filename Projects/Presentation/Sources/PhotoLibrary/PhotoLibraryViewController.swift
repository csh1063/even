//
//  PhotoLibraryViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Domain

final class PhotoLibraryViewController: BaseViewController {
    
    private var naviView: NaviBarView = NaviBarView(type: .title(.leading))
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<PhotoHeader, PhotoCellItemViewModel>!
    
    private var columnCount: Int = 3
    private var pinchBeginScale: CGFloat = 1.0
    
    private let viewModel: PhotoLibraryViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: PhotoLibraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setupBindings()
        self.checkPhotoPermission()
        self.setupPinchGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    private func checkPhotoPermission() {
        
        Task {
            let status = try await self.viewModel.checkPermission()
            if status.access {
                self.viewModel.send(.appear)
            } else {
                // 설정앱으로 유도
            }
        }
    }
    
    private func setupView() {
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createDynamicLayout(columns: columnCount))
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = Theme.background
        
        naviView.setTitle("사진첩",
                          color: Theme.text,
                          font: .systemFont(ofSize: 32, weight: .bold))
        naviView.setMessage("사진첩의 사진들",
                            color: Theme.text,
                            font: .systemFont(ofSize: 14, weight: .regular))
        
        configureDataSource()
        
        view.addSubview(naviView)
        
        view.addSubview(collectionView)
        
        naviView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.view)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.naviView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }
    }
    
    private func setupBindings() {
        let output = self.viewModel.transform()
        
        output.photos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photos in
                print("photos sink: ", photos.count)
                self?.applySnapshot(with: photos)
            }
            .store(in: &cancellables)
        
        output.totalCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] totalCount in
                
                self?.naviView.setMessage("사진 \(totalCount.formatted())장이 정렬되었습니다.",
                      color: Theme.text,
                      font: .systemFont(ofSize: 14, weight: .regular))
            }
            .store(in: &cancellables)
    }
    
    private func setupPinchGesture() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        collectionView.addGestureRecognizer(pinch)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            pinchBeginScale = gesture.scale

        case .changed:
            let scale = gesture.scale / pinchBeginScale
            print("pinchBeginScale", pinchBeginScale, ", scale", scale)
            let newLayout = createDynamicLayout(columns: columnCount, scale: scale)
            collectionView.setCollectionViewLayout(newLayout, animated: false)

            // 임계점마다 columnCount 업데이트 + 기준 리셋 → 계속 진행 가능
            if scale < 0.65 && columnCount < 11 {
                columnCount += 2
                pinchBeginScale = gesture.scale
            } else if scale > 1.35 && columnCount > 1 {
                columnCount = max(1, columnCount - 2)
                pinchBeginScale = gesture.scale
            }

        case .ended, .cancelled:
//            collectionView.setCollectionViewLayout(createLayout(columns: columnCount), animated: false)
            let scale = gesture.scale / pinchBeginScale
            let isZoomingIn = scale > 1.0
            
            // 방향별로 다르게
            collectionView.setCollectionViewLayout(
                createDynamicLayout(columns: columnCount),
                animated: isZoomingIn  // 확대는 animated, 축소는 false
            )
        default:
            break
        }
    }

    private func createDynamicLayout(columns: Int, scale: CGFloat = 1.0) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, env in
            let spacing = 4.0
            let sectionInset = 20.0
            let baseCount = CGFloat(columns)
            let isZoomingIn = scale >= 1.0

            let progress = isZoomingIn
                ? min((scale - 1.0) / 0.6, 1.0)
                : min((1.0 - scale) / 0.6, 1.0)
            
            let dynamicColumnCount = isZoomingIn
                ? baseCount
                : baseCount + (progress * 2.0)
            
            let contentWidth = env.container.contentSize.width
            - (sectionInset * 2) - (spacing * (dynamicColumnCount - 1))
            
            let groupHeight: CGFloat
            let sideItemWidth: CGFloat
            let normalItemWidth: CGFloat
            let startX: CGFloat

            if isZoomingIn {
                sideItemWidth = (contentWidth / baseCount) * progress
                normalItemWidth = (contentWidth + sideItemWidth * 2) / baseCount
                groupHeight = normalItemWidth  // 너비에 맞춰 정사각형
                startX = -sideItemWidth
            } else {
                groupHeight = contentWidth / dynamicColumnCount
                let targetCount = baseCount + 2.0
                sideItemWidth = (contentWidth / targetCount) * progress
                normalItemWidth = (contentWidth - sideItemWidth * 2) / baseCount
                startX = 0
            }

            let totalItemsInRow = isZoomingIn ? Int(baseCount) : Int(baseCount) + 2

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(groupHeight)
            )

            let group = NSCollectionLayoutGroup.custom(layoutSize: groupSize) { _ in
                var items = [NSCollectionLayoutGroupCustomItem]()
                var currentX = startX

                for i in 0..<totalItemsInRow {
                    let isEdge = !isZoomingIn && (i == 0 || i == totalItemsInRow - 1)
                    let width = isEdge ? sideItemWidth : normalItemWidth
                    let frame = CGRect(
                        x: currentX + sectionInset,
                        y: spacing,
                        width: width,
                        height: groupHeight - spacing
                    )
                    items.append(NSCollectionLayoutGroupCustomItem(frame: frame))
                    currentX += width + spacing // 다음 아이템 이동 시 간격만큼 더 이동
                }
                return items
            }
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(50)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            header.pinToVisibleBounds = true
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [header]
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
            
            return section
        }
    }
}

extension PhotoLibraryViewController {
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PhotoCell, PhotoCellItemViewModel> { cell, indexPath, cellViewModel in
            cell.configure(with: cellViewModel, index: indexPath.row)   // weak self도 필요 없어짐
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<PhotoSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { headerView, _, indexPath in
            let sections = Array(self.dataSource.snapshot().sectionIdentifiers)
            headerView.configure(with: sections[indexPath.section])
        }
        
        dataSource = UICollectionViewDiffableDataSource<PhotoHeader, PhotoCellItemViewModel>(collectionView: collectionView) {
            collectionView, indexPath, cellViewModel in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: cellViewModel)
        }
        
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    private func applySnapshot(with photos: [PhotoHeader: [PhotoCellItemViewModel]]) {
        var snapshot = NSDiffableDataSourceSnapshot<PhotoHeader, PhotoCellItemViewModel>()

        let sections: [PhotoHeader] = Array(photos.keys).sorted { $0.title > $1.title}
        
        snapshot.appendSections(sections)
        
        sections.forEach { section in
            snapshot.appendItems(photos[section] ?? [], toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
