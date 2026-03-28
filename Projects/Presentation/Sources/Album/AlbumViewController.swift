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
    
    private var naviView: NaviBarView = NaviBarView(type: .title(.leading))
    
    private let progressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let folderProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let locationProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let locationFolderProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    
    // for simulator test
    private let dummyButton: UIButton = UIButton()
        .withTitle("더미", for: .normal)
        .withTitleColor(.Theme.nickel, for: .normal)
    
    private var collectionView: UICollectionView = {

        let space: CGFloat = 2
        let count: CGFloat = 2
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
        collectionView.backgroundColor = .Theme.white

        return collectionView
    }()
    
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
        
        naviView.setTitle("Albums")
        naviView.addRightButtons([(.reset, .Theme.secondary), (.analysis, .Theme.primary)])
        
        collectionView.delegate = self
        
        progressBar.isHidden = true
        folderProgressBar.isHidden = true
        locationProgressBar.isHidden = true
        locationFolderProgressBar.isHidden = true
        
        progressBar.trackTintColor = .Theme.gray
        folderProgressBar.trackTintColor = .Theme.gray
        locationProgressBar.trackTintColor = .Theme.gray
        locationFolderProgressBar.trackTintColor = .Theme.gray
        
        progressBar.progressTintColor = .Theme.primary
        folderProgressBar.progressTintColor = .Theme.primary
        locationProgressBar.progressTintColor = .Theme.primary
        locationFolderProgressBar.progressTintColor = .Theme.primary
        
        view.addSubview(collectionView)
        
        view.addSubview(progressBar)
        view.addSubview(folderProgressBar)
        view.addSubview(locationProgressBar)
        view.addSubview(locationFolderProgressBar)
        
        view.addSubview(naviView)
        view.addSubview(dummyButton)
        
        self.configureDataSource()
        
        naviView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.view)
        }
        
        progressBar.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view.snp.centerX)
            make.top.equalTo(naviView.snp.bottom).offset(2)
        }
        
        folderProgressBar.snp.makeConstraints { make in
            make.trailing.equalTo(view)
            make.leading.equalTo(view.snp.centerX)
            make.top.equalTo(naviView.snp.bottom).offset(2)
        }
        
        locationProgressBar.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view.snp.centerX)
            make.top.equalTo(naviView.snp.bottom).offset(4)
        }
        
        locationFolderProgressBar.snp.makeConstraints { make in
            make.trailing.equalTo(view)
            make.leading.equalTo(view.snp.centerX)
            make.top.equalTo(naviView.snp.bottom).offset(4)
        }
        
        dummyButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.naviView)
            make.trailing.equalTo(self.naviView).offset(-120)
            make.width.equalTo(60)
        }
        
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

        naviView.rightPublisher
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
        
        dummyButton.tapPublisher
            .sink { [weak self] button in
                guard let self else {return}
                self.viewModel.send(.dummy)
            }
            .store(in: &cancellables)
        
        output.folders
            .receive(on: DispatchQueue.main)
            .map { [weak self] folders -> [FolderCellItemViewModel] in
                guard let self else { return [] }
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
            cell.configure(with: cellViewModel)   // weak self도 필요 없어짐
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
