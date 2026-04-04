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
        label.text = "MOA"
        
        return label
    }()
    
    private var descLabel: UILabel = {
        let label = UILabel()

        label.numberOfLines = 0
        
        let attriString = NSMutableAttributedString(string: "모아\n\n\n",
                                                    attributes: [
                                                        .foregroundColor: UIColor.black,
                                                        .font: UIFont.systemFont(ofSize: 12)
                                                    ])
        attriString.append(NSMutableAttributedString(string: "당신의 순간을 모으다",
                                                     attributes: [
                                                        .foregroundColor: UIColor.darkGray,
                                                        .font: UIFont.systemFont(ofSize: 16)
                                                     ]))
        label.attributedText = attriString
        label.textAlignment = .center
        
        return label
    }()
    
    private let viewModel: SplashViewModel
    
    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        self.setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError(Self.fatalMessage)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewModel.send(.appear)
    }
    
    private func setupView() {
        
        view.addSubview(nameLabel)
        view.addSubview(descLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).offset(-80)
        }
        
        descLabel.snp.makeConstraints { make in
            make.centerX.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
        }
    }
}
