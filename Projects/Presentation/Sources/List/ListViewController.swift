////
////  ListViewController.swift
////  Presentation
////
////  Created by sanghyeon on 12/22/25.
////  Copyright © 2025 sanghyeon. All rights reserved.
////
//
//import Foundation
//import UIKit
//
//final class ListViewController: BaseViewController {
//    
//    private let mainLabel: UILabel = UILabel()
//    
//    private let viewModel: ListViewModel
//    
//    init(viewModel: ListViewModel) {
//        self.viewModel = viewModel
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError(Self.fatalMessage)
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self.setupView()
//        self.setupBindings()
//    }
//    
//    private func setupView() {
//        
//        mainLabel.text = "LIST"
//        
//        view.addSubview(mainLabel)
//        
//        mainLabel.snp.makeConstraints { make in
//            make.center.equalTo(view)
//        }
//    }
//    
//    private func setupBindings() {
//        
//
//    }
//}
