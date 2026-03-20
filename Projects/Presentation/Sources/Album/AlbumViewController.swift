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
        
        Task {
            await testVision()
        }
    }
    
    private func setupView() {
        
        mainLabel.text = "Albums"
        button.setTitle("고고", for: .normal)
        button.setTitleColor(.Theme.midnight, for: .normal)
        
        view.addSubview(mainLabel)
        view.addSubview(progressLabel)
        view.addSubview(button)
        
        mainLabel.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
        progressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(mainLabel)
            make.leading.equalTo(mainLabel.snp.trailing)
        }
        
        button.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.trailing.equalTo(self.view)
        }
    }
    
    private func setupBindings() {
        
        button.tapPublisher
            .sink { [weak self] button in
                guard let self else {return}
                self.viewModel.send(.analysis)
            }
            .store(in: &cancellables)
    }
    
    func testVision() async {
//        print("테스트 시작")
//        
//        // 테스트용 이미지 직접 생성
//        let size = CGSize(width: 100, height: 100)
//        UIGraphicsBeginImageContext(size)
//        UIColor.red.setFill()
//        UIRectFill(CGRect(origin: .zero, size: size))
//        let testImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        
//        guard let cgImage = testImage?.cgImage else {
//            print("cgImage 생성 실패")
//            return
//        }
//        
//        print("cgImage 생성 성공")
//        
//        let request = VNClassifyImageRequest()
//        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
//        
//        do {
//            try handler.perform([request])
//            print("perform 성공, 결과:", request.results?.count ?? 0)
//        } catch {
//            print("perform 에러:", error)
//        }
    }
}
