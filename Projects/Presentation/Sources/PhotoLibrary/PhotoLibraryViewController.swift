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
    
    //    private var collectionView: UICollectionView = {
    //
    //        let space: CGFloat = 2
    //        let count: CGFloat = 3
    ////        let height = AppInfo.shared.bannerHeight
    //        let layout = UICollectionViewFlowLayout()
    //        layout.scrollDirection = .vertical
    //        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    //        layout.minimumLineSpacing = space
    //        layout.minimumInteritemSpacing = space
    //
    //        let width = ((UIScreen.main.bounds.width - (space * (count + 1))) / count)
    //
    //        layout.itemSize = CGSize(width: width, height: width)
    //
    //        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    //        collectionView.isScrollEnabled = true
    //        collectionView.showsVerticalScrollIndicator = false
    //        collectionView.backgroundColor = .clear
    //        collectionView.contentInset = UIEdgeInsets(top: 12, left: space, bottom: 0, right: space)
    //
    //        return collectionView
    //    }()
    
    private var collectionView: UICollectionView!
    
    private var columnCount: Int = 3
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>!
    
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
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createDynamicLayout(columns: columnCount, scale: 1.0))
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .Theme.background
        
        naviView.setTitle("PHOTO LIBRARY", color: .Theme.text)
        naviView.translatesAutoresizingMaskIntoConstraints = false
        
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
            .map { [weak self] photos -> [PhotoCellItemViewModel] in
                guard let self else { return [] }
                return photos.map {
                    PhotoCellItemViewModel(
                        localIdentifier: $0.localIdentifier,
                        imageLoader: self.viewModel
                    )
                }
            }
            .sink { [weak self] photos in
                print("photos sink: ", photos.count)
                self?.applySnapshot(with: photos)
            }
            .store(in: &cancellables)
    }
    
    private func setupPinchGesture() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        collectionView.addGestureRecognizer(pinch)
    }
    
    private var pinchBeginScale: CGFloat = 1.0

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
            if scale < 0.75 && columnCount < 11 {
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
                createLayout(columns: columnCount),
                animated: isZoomingIn  // 확대는 animated, 축소는 false
            )
        default:
            break
        }
    }

    private func createDynamicLayout(columns: Int, scale: CGFloat) -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, env in
            let contentWidth = env.container.contentSize.width
            let baseCount = CGFloat(columns)
            let isZoomingIn = scale > 1.0
//            let progress = isZoomingIn ? min(scale - 1.0, 1.0) : min(1.0 - scale, 1.0)
            let progress = isZoomingIn
                ? min((scale - 1.0) / 0.35, 1.0)   // 1.0 → 1.35 구간
                : min((1.0 - scale) / 0.25, 1.0)   // 1.0 → 0.75 구간
            
            print("progress", progress)

            // 확대 시 높이 고정 (baseCount 기준), 축소 시에만 높이 변화
            let dynamicColumnCount = isZoomingIn
                ? baseCount  // 확대 시 높이 고정
                : baseCount + (progress * 2.0)
            
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
                    items.append(NSCollectionLayoutGroupCustomItem(frame: CGRect(x: currentX, y: 0, width: width, height: groupHeight)))
                    currentX += width
                }
                return items
            }

            return NSCollectionLayoutSection(group: group)
        }
    }
    
    private func createLayout(columns: Int) -> UICollectionViewLayout {
        // 1. 아이템 너비: 1.0이 아니라 반드시 1/n로 직접 지정
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 1, leading: 1, bottom: 1, trailing: 1)
        
        // 2. 그룹 높이: 너비 대비 1/n로 지정해서 정사각형 유지
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / CGFloat(columns))
        )
        
        // 3. iOS 16+ : count 명시해서 강제 분할
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: columns
        )
        
        return UICollectionViewCompositionalLayout(section: NSCollectionLayoutSection(group: group))
    }
}

extension PhotoLibraryViewController {
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PhotoCell, PhotoCellItemViewModel> { cell, indexPath, cellViewModel in
            cell.configure(with: cellViewModel)   // weak self도 필요 없어짐
        }
        
        dataSource = UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>(collectionView: collectionView) {
            collectionView, indexPath, cellViewModel in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: cellViewModel)
        }
    }
    
    private func applySnapshot(with photos: [PhotoCellItemViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PhotoCellItemViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(photos)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
