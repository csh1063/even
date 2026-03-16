//
//  MainViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

final class MainViewController: CustomTabBarController {
    
    private let viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("MainViewController does not support NSCoding")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.setLayoutMargin(height: 56, bottom: 4,
//                             leading: 40, trailing: 40, cornerRadius: 28)
        
        self.setShadow(color: .black, alpha: 0.1, x: 0, y: 4, blur: 6)
    }
    
    private func setupView() {
        
    }
}
