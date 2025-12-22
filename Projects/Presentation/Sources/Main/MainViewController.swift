//
//  MainViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

final class MainViewController: BaseViewController {
    
    private let viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("SplashViewController does not support NSCoding")
    }
    
    private func setupView() {
        
    }
}
