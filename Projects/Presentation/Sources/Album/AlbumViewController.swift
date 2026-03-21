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
    
    private let mainLabel: UILabel = UILabel()
    private let progressLabel: UILabel = UILabel()
    private let locationProgressLabel: UILabel = UILabel()
    
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
        progressLabel.isHidden = true
        locationProgressLabel.isHidden = true
        button.setTitle("고고", for: .normal)
        button.setTitleColor(.Theme.midnight, for: .normal)
        
        view.addSubview(mainLabel)
        view.addSubview(progressLabel)
        view.addSubview(locationProgressLabel)
        view.addSubview(button)
        
        mainLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view).offset(-80)
        }
        progressLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(mainLabel.snp.bottom)
        }
        locationProgressLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(progressLabel.snp.bottom)
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
                self?.progressLabel.text = String(format: "%.2f", ratio)
            }
            .store(in: &cancellables)
        
        viewModel.$isAnalyzing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.progressLabel.isHidden = !isLoading
            }
            .store(in: &cancellables)
        
        viewModel.$locationProgressRatio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ratio in
                self?.locationProgressLabel.text = String(format: "%.2f", ratio)
            }
            .store(in: &cancellables)
        
        viewModel.$isLocationAnalyzing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.locationProgressLabel.isHidden = !isLoading
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
