//
//  HomeViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

final class HomeViewController: BaseViewController {
    
    private var mainLabel: UILabel = UILabel()
    
    private let viewModel: HomeViewModel
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }
    
    private func setupView() {
        
        mainLabel.text = "HOME"
        
        view.addSubview(mainLabel)
        
        mainLabel.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
    }
}
