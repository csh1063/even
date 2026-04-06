//
//  LabelsViewController.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Domain
import Combine

final class LabelsViewController: BaseViewController {
    
    private let naviView: NaviBarView = NaviBarView()
    
    private lazy var collectionView: UICollectionView = {
        let layout = LeftAlignedFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize  // 자동 크기
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 40, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .Theme.background
        return collectionView
    }()
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private let viewModel: LabelsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    public init(viewModel: LabelsViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder: NSCoder) {
        fatalError("LabelsViewController does not support NSCoding")
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
    
    func setupView() {
        
        naviView.setTitle("사진 라벨")
        
        view.addSubview(naviView)
        view.addSubview(collectionView)
        
        naviView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.view)
        }
        
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.view)
            make.top.equalTo(naviView.snp.bottom)
        }
        
        self.configureDataSource()
    }
    
    func setupBindings() {
        
        naviView.leftPublisher
            .sink { [weak self] _ in
                print("back!")
                self?.viewModel.pop?()
            }
            .store(in: &cancellables)
        
        let output = viewModel.transform()
        
        output.photoLabels
            .receive(on: DispatchQueue.main)
//            .map { [weak self] photos -> [PhotoCellItemViewModel] in
//                guard let self else { return [] }
//                return photos.map {
//                    PhotoCellItemViewModel(
//                        localIdentifier: $0.localIdentifier,
//                        imageLoader: self.viewModel
//                    )
//                }
//            }
            .sink { [weak self] photoLabels in
                print("photoLabels sink: ", photoLabels.count)
                self?.applySnapshot(with: photoLabels)
            }
            .store(in: &cancellables)
    }
}

extension LabelsViewController {
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<PhotoLabelCell, String> { cell, indexPath, cellViewModel in
            cell.configure(with: cellViewModel)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Int, String>(collectionView: collectionView) {
            collectionView, indexPath, cellViewModel in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: cellViewModel)
        }
    }
    
    private func applySnapshot(with labels: [String]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(labels)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
