//
//  SplashViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

final class SplashViewController: BaseViewController {
    
    private var nameLabel: UILabel = {
        let label = UILabel()
        
        label.font = UIFont.systemFont(ofSize: 32)
        label.textColor = .black
        label.textAlignment = .center
        label.text = "EVEN"
        
        return label
    }()
    
    private var descLabel: UILabel = {
        let label = UILabel()

        label.numberOfLines = 2
        
        let attriString = NSMutableAttributedString(string: "이",
                                                    attributes: [
                                                        .foregroundColor: UIColor.black,
                                                        .font: UIFont.systemFont(ofSize: 16)
                                                    ])
        attriString.append(NSMutableAttributedString(string: " 요리\n",
                                                     attributes: [
                                                        .foregroundColor: UIColor.darkGray,
                                                        .font: UIFont.systemFont(ofSize: 12)
                                                     ]))
        attriString.append(NSMutableAttributedString(string: "분",
                                                     attributes: [
                                                        .foregroundColor: UIColor.black,
                                                        .font: UIFont.systemFont(ofSize: 16)
                                                     ]))
        attriString.append(NSMutableAttributedString(string: "석해줘",
                                                     attributes: [
                                                        .foregroundColor: UIColor.darkGray,
                                                        .font: UIFont.systemFont(ofSize: 12)
                                                     ]))
        label.attributedText = attriString
        
        return label
    }()
    
    private let viewModel: SplashViewModel
    
    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("SplashViewController does not support NSCoding")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewModel.input.send(.viewWillAppear)
    }
    
    private func setupView() {
        
        view.addSubview(nameLabel)
        view.addSubview(descLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.center.equalTo(self.view)
        }
        
        descLabel.snp.makeConstraints { make in
            make.centerX.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
    }
}
