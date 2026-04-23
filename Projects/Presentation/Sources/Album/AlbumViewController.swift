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
    
    private let progressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let folderProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let locationProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let locationFolderProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    
    // for simulator test
//    private let dummyButton: UIButton = UIButton()
//        .withTitle("더미", for: .normal)
//        .withTitleColor(Theme.nickel, for: .normal)
    
    private var collectionView: UICollectionView = {

        let space: CGFloat = 2
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
    
//    private var collectionView: UICollectionView = {
//        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
//        collectionView.isScrollEnabled = true
//        collectionView.showsVerticalScrollIndicator = false
//        collectionView.backgroundColor = Theme.background
//        return collectionView
//    }()
//
//    private static func makeLayout() -> UICollectionViewCompositionalLayout {
//        let space: CGFloat = 2
//        let count: CGFloat = 2
//        let margin: CGFloat = 8
//
//        // Item: 그룹 너비의 1/2
//        let itemSize = NSCollectionLayoutSize(
//            widthDimension: .fractionalWidth(1 / count),
//            heightDimension: .fractionalHeight(1.0)
//        )
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: space, trailing: space)
//
//        // Group: 화면 너비 100%, 높이 = 셀 너비 (정사각형)
//        let itemWidth = (UIScreen.main.bounds.width - (space * (count - 1)) - (margin * 2)) / count
//        let groupSize = NSCollectionLayoutSize(
//            widthDimension: .fractionalWidth(1.0),
//            heightDimension: .absolute(itemWidth)
//        )
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
//
//        // Section
//        let section = NSCollectionLayoutSection(group: group)
//        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: margin, bottom: 80, trailing: margin - space)
//
//        return UICollectionViewCompositionalLayout(section: section)
//    }
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewModel.send(.appear)
    }
    
    private func setupView() {
        
        naviView.setTitle("주제별 앨범",
                          color: Theme.text,
                          font: .systemFont(ofSize: 32, weight: .bold))
        naviView.setMessage("사진들이 개 앨범으로 정리되었어요",
                            color: Theme.text,
                            font: .systemFont(ofSize: 14, weight: .regular))
        
//        naviView.addRightButtons([(.reset, Theme.negative), (.analysis, Theme.primary)])
        naviView.addButtons([RightButton(type: .reset, color: Theme.negative),
                             RightButton(type: .analysis, color: Theme.text)])
        
        collectionView.delegate = self
        
        progressBar.isHidden = true
        folderProgressBar.isHidden = true
        locationProgressBar.isHidden = true
        locationFolderProgressBar.isHidden = true
        
        progressBar.trackTintColor = Theme.surface
        folderProgressBar.trackTintColor = Theme.surface
        locationProgressBar.trackTintColor = Theme.surface
        locationFolderProgressBar.trackTintColor = Theme.surface
        
        progressBar.progressTintColor = Theme.primary
        folderProgressBar.progressTintColor = Theme.primary
        locationProgressBar.progressTintColor = Theme.primary
        locationFolderProgressBar.progressTintColor = Theme.primary
        
        view.addSubview(collectionView)
        
        view.addSubview(progressBar)
        view.addSubview(folderProgressBar)
        view.addSubview(locationProgressBar)
        view.addSubview(locationFolderProgressBar)
        
        view.addSubview(naviView)
//        view.addSubview(dummyButton)
        
        self.configureDataSource()
        
        naviView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.view)
        }
        
        progressBar.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.8)
            make.top.equalTo(naviView.snp.bottom).offset(2)
        }
        
        folderProgressBar.snp.makeConstraints { make in
            make.trailing.equalTo(view)
            make.leading.equalTo(progressBar.snp.trailing)
            make.top.equalTo(naviView.snp.bottom).offset(2)
        }
        
        locationProgressBar.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.width.equalTo(view).multipliedBy(0.8)
            make.top.equalTo(naviView.snp.bottom).offset(4)
        }
        
        locationFolderProgressBar.snp.makeConstraints { make in
            make.trailing.equalTo(view)
            make.leading.equalTo(locationProgressBar.snp.trailing)
            make.top.equalTo(naviView.snp.bottom).offset(4)
        }
        
//        dummyButton.snp.makeConstraints { make in
//            make.bottom.equalTo(self.naviView)
//            make.trailing.equalTo(self.naviView).offset(-120)
//            make.width.equalTo(60)
//        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(naviView.snp.bottom)
            make.bottom.leading.trailing.equalTo(self.view)
        }
    }
    
    private func setupBindings() {
        
        let output = self.viewModel.transform()
        output.progressRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.progressBar.progress = Float(ratio)
            }
            .store(in: &cancellables)
        
        output.autoFolderProgressRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.folderProgressBar.progress = Float(ratio)
            }
            .store(in: &cancellables)
        
        output.locationProgressRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.locationProgressBar.progress = Float(ratio)
            }
            .store(in: &cancellables)
        
        output.locationFolderProgressRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.locationFolderProgressBar.progress = Float(ratio)
            }
            .store(in: &cancellables)
        
        output.isAnalyzing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.progressBar.isHidden = !isLoading
                self?.folderProgressBar.isHidden = !isLoading
                self?.locationProgressBar.isHidden = !isLoading
                self?.locationFolderProgressBar.isHidden = !isLoading
            }
            .store(in: &cancellables)

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
        
//        dummyButton.tapPublisher
//            .sink { [weak self] button in
//                guard let self else {return}
//                self.viewModel.send(.dummy)
//            }
//            .store(in: &cancellables)
        
        output.folders
            .receive(on: DispatchQueue.main)
            .map { [weak self] folders -> [FolderCellItemViewModel] in
                guard let self else { return [] }
                
                self.naviView.setMessage(
                    "사진들이 \(folders.count)개 앨범으로 정리되었어요",
                    color: Theme.text,
                    font: .systemFont(ofSize: 14, weight: .regular))
                
                return folders.map { FolderCellItemViewModel(folder: $0, imageLoader: self.viewModel) }
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
