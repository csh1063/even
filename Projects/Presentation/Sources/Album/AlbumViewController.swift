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
import Vision

final class AlbumViewController: BaseViewController {
    
    private let naviView: NaviBarView = NaviBarView(type: .title(.leading))
    
    private var collectionView: UICollectionView = {

        let space: CGFloat = 10
        let count: CGFloat = 2
        let margin: CGFloat = 8
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = space
        layout.minimumInteritemSpacing = space
        
        let width = ((UIScreen.main.bounds.width - (space * (count - 1))) - (margin * 2)) / count
        
        layout.estimatedItemSize = CGSize(width: floor(width), height: width) // 대략적인 높이
        layout.itemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 12, left: margin, bottom: 80, right: margin)
        collectionView.backgroundColor = Theme.background

        return collectionView
    }()
    
    private var emptyView: AlbumEmtpyView = AlbumEmtpyView()
    
    private var dataSource: UICollectionViewDiffableDataSource<Int, FolderCellItemViewModel>!
    
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
    
    private func setupView() {
        
        naviView.setTitle("주제별 앨범",
                          color: Theme.textPrimary,
                          font: .systemFont(ofSize: 32, weight: .bold))
        naviView.setMessage("사진이 개 앨범으로 정리되었어요",
                            color: Theme.textPrimary,
                            font: .systemFont(ofSize: 14, weight: .regular))
        
        naviView.addButtons([RightButton(type: .reset),
                             RightButton(type: .analysis)])
        
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
        output.folders
            .receive(on: DispatchQueue.main)
            .map { [weak self] folders -> [FolderCellItemViewModel] in
                guard let self else { return [] }
                
                if folders.count == 0 {
                    self.emptyView.isHidden = false
                    self.naviView.isHidden = true
                    return []
                } else {
                    self.emptyView.isHidden = true
                    self.naviView.isHidden = false
                    self.naviView.setMessage(
                        "\(folders.count)개 앨범으로 정리되었어요",
                        color: Theme.textPrimary,
                        font: .systemFont(ofSize: 14, weight: .regular))
                    
                    return folders.map { FolderCellItemViewModel(folder: $0, imageLoader: self.viewModel) }
                }
            }
            .sink { [weak self] folders in
                print("folders sink: ", folders.count)
                self?.applySnapshot(with: folders)
            }
            .store(in: &cancellables)
    }
}

extension AlbumViewController {
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<FolderCell, FolderCellItemViewModel> { cell, indexPath, cellViewModel in
            cell.configure(with: cellViewModel, index: indexPath.row)   // weak self도 필요 없어짐
        }
        
        dataSource = UICollectionViewDiffableDataSource<Int, FolderCellItemViewModel>(collectionView: collectionView) {
            collectionView, indexPath, cellViewModel in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: cellViewModel)
        }
    }
    
    private func applySnapshot(with folders: [FolderCellItemViewModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, FolderCellItemViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(folders)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension AlbumViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cellViewModel = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.send(.selectItem(cellViewModel.folder))
    }

}

extension AlbumViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}
