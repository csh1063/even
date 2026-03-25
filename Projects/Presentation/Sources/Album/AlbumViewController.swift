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
    
    private var naviView: UIView = UIView()
    private let mainLabel: UILabel = UILabel()
    private let progressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let folderProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let locationProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let locationFolderProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    
    private let analysisButton: UIButton = UIButton()
    private let clearButton: UIButton = UIButton()
    
    private var collectionView: UICollectionView = {

        let space: CGFloat = 2
        let count: CGFloat = 2
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
        
        naviView.backgroundColor = .Theme.white
        mainLabel.text = "Albums"
        mainLabel.textColor = .Theme.midnight
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
        analysisButton.setTitle("분석", for: .normal)
        analysisButton.setTitleColor(.Theme.primary, for: .normal)
        clearButton.setTitle("초기", for: .normal)
        clearButton.setTitleColor(.Theme.secondary, for: .normal)

        view.addSubview(collectionView)
        
        view.addSubview(progressBar)
        view.addSubview(folderProgressBar)
        view.addSubview(locationProgressBar)
        view.addSubview(locationFolderProgressBar)
        
        view.addSubview(naviView)
        naviView.addSubview(mainLabel)
        view.addSubview(analysisButton)
        view.addSubview(clearButton)
        
        self.configureDataSource()
        
        naviView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(self.view)
            make.height.equalTo(48)
        }
        
        mainLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(naviView)
            make.leading.equalTo(naviView).offset(20)
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
        
        analysisButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.naviView)
            make.trailing.equalTo(self.view)
            make.width.equalTo(60)
        }
        
        clearButton.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.naviView)
            make.trailing.equalTo(self.analysisButton.snp.leading)
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

        analysisButton.tapPublisher
            .sink { [weak self] button in
                guard let self else {return}
                self.viewModel.send(.analysis)
            }
            .store(in: &cancellables)
        
        clearButton.tapPublisher
            .sink { [weak self] button in
                guard let self else {return}
                self.viewModel.send(.clear)
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
