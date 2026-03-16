//
//  HomeViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Domain

final class HomeViewController: BaseViewController {
    
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
//        collectionView.isPagingEnabled = true
//        collectionView.alwaysBounceHorizontal = true
//        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false

        return collectionView
    }()
    private var dataSource: UICollectionViewDiffableDataSource<Int, PhotoInAlbum>!
    
    private let viewModel: HomeViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.setupView()
        
        self.setupBindings()
    }
    
    required public init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Task {
            let status = try await self.viewModel.checkPermission()
            if status.access {
                self.viewModel.send(.appear)
            } else {
                //
            }
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
    }
    
    private func setupView() {
        
        mainLabel.text = "HOME"
        
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

extension HomeViewController {
    
    // DataSource 설정
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<HomePhotoCell, PhotoInAlbum> { [weak self] cell, indexPath, photo in
            guard let self else { return }
            cell.configure(with: photo, viewModel: self.viewModel)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Int, PhotoInAlbum>(collectionView: collectionView) {
            (collectionView, indexPath, photo) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: photo)
        }
    }

    // 3. 실제 데이터 적용 (Snapshot)
    private func applySnapshot(with photos: [PhotoInAlbum]) {
        print("스냅샷 적용! 데이터 개수: \(photos.count)") // 로그 추가
        var snapshot = NSDiffableDataSourceSnapshot<Int, PhotoInAlbum>()
        snapshot.appendSections([0])
        snapshot.appendItems(photos)
        
        // 데이터가 바뀌면 Diff알고리즘이 알아서 계산해서 업데이트합니다.
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
