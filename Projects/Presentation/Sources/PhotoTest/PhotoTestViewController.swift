//
//  PhotoTestViewController.swift
//  Presentation
//
//  Created by sanghyeon on 4/8/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

final class PhotoTestViewController: BaseViewController {
    
    private let naviView = NaviBarView()
    private let test1Button = UIButton()
    private let test2Button = UIButton()
    private let test3Button = UIButton()
    
    private let viewModel: PhotoTestViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: PhotoTestViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("PhotoTestViewController does not support NSCoding.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
        self.setupBindings()
    }
    
    private func setupView() {
        
        naviView.setTitle("laboratory".uppercased())
        naviView.addButtons([LeftButton(type: .back, color: .Theme.text)])
        
        test1Button.setTitle("좌표별 갯수", for: .normal)
        test1Button.setTitleColor(.Theme.text, for: .normal)
        
        test2Button.setTitle("한국 갯수", for: .normal)
        test2Button.setTitleColor(.Theme.text, for: .normal)
        
        test3Button.setTitle("주소 변환", for: .normal)
        test3Button.setTitleColor(.Theme.text, for: .normal)
        
        view.addSubview(test1Button)
        view.addSubview(test2Button)
        view.addSubview(test3Button)
        view.addSubview(naviView)
        
        naviView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(view)
        }
        
        test1Button.snp.makeConstraints { make in
            make.top.equalTo(naviView.snp.bottom).offset(4)
            make.leading.trailing.equalTo(view)
        }
        
        test2Button.snp.makeConstraints { make in
            make.top.equalTo(test1Button.snp.bottom).offset(4)
            make.leading.trailing.equalTo(view)
        }
        
        test3Button.snp.makeConstraints { make in
            make.top.equalTo(test2Button.snp.bottom).offset(4)
            make.leading.trailing.equalTo(view)
        }
    }
    
    private func setupBindings() {
        
        naviView.publisher
            .sink { _ in
                self.viewModel.pop?()
            }
            .store(in: &cancellables)
        
        test1Button.tapPublisher
            .sink { _ in
                self.viewModel.send(.sameCount)
            }
            .store(in: &cancellables)
        
        test2Button.tapPublisher
            .sink { _ in
                self.viewModel.send(.koreanCount)
            }
            .store(in: &cancellables)
        
        test3Button.tapPublisher
            .sink { _ in
                self.viewModel.send(.coorToAddress)
            }
            .store(in: &cancellables)
    }
}
