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
    private let progressLabel: UILabel = UILabel()
    private let progressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let folderProgressLabel: UILabel = UILabel()
    private let folderProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private let locationProgressLabel: UILabel = UILabel()
    private let locationProgressBar: UIProgressView = UIProgressView(progressViewStyle: .bar)
    
    private let button: UIButton = UIButton()
    
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
    
    private func setupView() {
        
        mainLabel.text = "Albums"
        mainLabel.textColor = .Theme.midnight
        progressLabel.isHidden = true
        folderProgressLabel.isHidden = true
        locationProgressLabel.isHidden = true
        progressBar.isHidden = true
        folderProgressBar.isHidden = true
        locationProgressBar.isHidden = true
        progressBar.trackTintColor = .Theme.gray
        folderProgressBar.trackTintColor = .Theme.gray
        locationProgressBar.trackTintColor = .Theme.gray
        progressBar.progressTintColor = .Theme.primary
        folderProgressBar.progressTintColor = .Theme.primary
        locationProgressBar.progressTintColor = .Theme.primary
        button.setTitle("고고", for: .normal)
        button.setTitleColor(.Theme.midnight, for: .normal)
        
//        view.addSubview(mainLabel)
        view.addSubview(progressLabel)
        view.addSubview(locationProgressLabel)
        view.addSubview(folderProgressLabel)
        view.addSubview(progressBar)
        view.addSubview(folderProgressBar)
        view.addSubview(locationProgressBar)
        
        view.addSubview(naviView)
        naviView.addSubview(mainLabel)
        view.addSubview(button)
        
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
            make.leading.trailing.equalTo(view)
            make.top.equalTo(progressBar.snp.bottom)
        }
        
        progressLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view).offset(-40)
        }
        
        folderProgressLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(progressLabel.snp.bottom)
        }
        
        locationProgressLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(folderProgressLabel.snp.bottom)
        }
        
        button.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.trailing.equalTo(self.view)
        }
    }
    
    private func setupBindings() {
        
        viewModel.$progressRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.progressLabel.text = String(format: "%.3f", ratio)
                self?.progressBar.progress = Float(ratio)
            }
            .store(in: &cancellables)
        
        viewModel.$autoFolderProgressRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.folderProgressLabel.text = String(format: "%.3f", ratio)
                self?.folderProgressBar.progress = Float(ratio)
            }
            .store(in: &cancellables)
        
        viewModel.$locationProgressRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.locationProgressLabel.text = String(format: "%.3f", ratio)
                self?.locationProgressBar.progress = Float(ratio / 2.0)
            }
            .store(in: &cancellables)
        
        viewModel.$isAnalyzing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.progressLabel.isHidden = !isLoading
                self?.folderProgressLabel.isHidden = !isLoading
                self?.locationProgressLabel.isHidden = !isLoading
                self?.progressBar.isHidden = !isLoading
                self?.folderProgressBar.isHidden = !isLoading
                self?.locationProgressBar.isHidden = !isLoading
            }
            .store(in: &cancellables)

        button.tapPublisher
            .sink { [weak self] button in
                guard let self else {return}
                self.viewModel.send(.analysis)
            }
            .store(in: &cancellables)
    }
}
