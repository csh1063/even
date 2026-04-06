//
//  AlbumDetailViewController.swift
//  Presentation
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Domain

final class AlbumDetailViewController: BaseViewController {
    
    private var naviView: NaviBarView = NaviBarView(type: .title(.leading))
    
    private var collectionView: UICollectionView = {

        let space: CGFloat = 2
        let count: CGFloat = 3
//        let height = AppInfo.shared.bannerHeight
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = space
        layout.minimumInteritemSpacing = space
        
        let width = (UIScreen.main.bounds.width - (space * (count + 1))) / count
        
        layout.itemSize = CGSize(width: width, height: width)

        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 8, left: space, bottom: 0, right: space)
        collectionView.backgroundColor = .clear

        return collectionView
    }()
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, PhotoCellItemViewModel>!
    
    private let viewModel: AlbumDetailViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: AlbumDetailViewModel) {
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewModel.send(.appear)
    }
    
    private func setupView() {
        
        naviView.addLeftButton(.back, color: .Theme.text)
        
        configureDataSource()
        
        view.addSubview(naviView)
        view.addSubview(collectionView)
        
        naviView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(self.view)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.naviView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }
    }
    
    private func setupBindings() {
        
        naviView.leftPublisher
            .sink { [weak self] _ in
                print("back!")
                self?.viewModel.pop?()
            }
            .store(in: &cancellables)
        
        let output = self.viewModel.transform()
        
        output.name
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.naviView.setTitle(name)
            }
            .store(in: &cancellables)
        
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
}

extension AlbumDetailViewController {
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
