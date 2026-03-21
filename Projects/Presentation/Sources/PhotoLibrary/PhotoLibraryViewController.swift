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
    
    private var naviView: UIView = UIView()
    private var mainLabel: UILabel = UILabel()
    private var collectionView: UICollectionView = {

        let space: CGFloat = 2
        let count: CGFloat = 3
//        let height = AppInfo.shared.bannerHeight
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = space
        layout.minimumInteritemSpacing = space
        
        let width = (UIScreen.main.bounds.width - (space * (count - 1))) / count
        
        layout.itemSize = CGSize(width: width, height: width)

        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false

        return collectionView
    }()
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
    
    private func setupBindings() {
        let output = self.viewModel.transform()
        
        output.photos
            .receive(on: DispatchQueue.main)
            .map { [weak self] photos -> [PhotoCellItemViewModel] in
                guard let self else { return [] }
                return photos.map { PhotoCellItemViewModel(photo: $0, imageLoader: self.viewModel) }
            }
            .sink { [weak self] photos in
                print("photos sink: ", photos.count)
                self?.applySnapshot(with: photos)
            }
            .store(in: &cancellables)
    }
    
    private func setupView() {
        
        mainLabel.text = "PHOTO LIBRARY"
        
        configureDataSource()
        
        view.addSubview(naviView)
        naviView.addSubview(mainLabel)
        
        view.addSubview(collectionView)
        
        naviView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(self.view)
            make.height.equalTo(48)
        }
        
        mainLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(naviView)
            make.leading.equalTo(naviView).offset(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.naviView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }
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
