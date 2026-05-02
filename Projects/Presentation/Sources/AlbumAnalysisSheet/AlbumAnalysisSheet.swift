//
//  AlbumAnalysisSheet.swift
//  Presentation
//
//  Created by sanghyeon on 4/27/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

final class AlbumAnalysisSheet: UIViewController {

    var progress: AnalyzeProgress
    var onEnd: (() -> Void)?
    
    private let grabberView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.strokeStrong
        view.layer.cornerRadius = 2.5
        return view
    }()

    private let circleBackground: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surfaceCool
        view.layer.cornerRadius = 42
        return view
    }()

    private let progressIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = Theme.primary
        view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        view.startAnimating()
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "새 앨범 만드는 중"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = Theme.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "새 사진을 정리하고 관련 사진끼리 앨범을 만들고 있어요"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = Theme.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let photoRow = ProgressRow(icon: "photo.badge.plus", title: "사진 분석 중")
    private let albumRow = ProgressRow(icon: "square.stack.3d.up.fill", title: "앨범 생성 중")

    private let locationNoteView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surfaceCool
        view.layer.cornerRadius = 14
        return view
    }()

    private let locationIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "location.fill.viewfinder"))
        imageView.tintColor = Theme.secondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = "이후 위치 기반 정리는 백그라운드에서 계속 진행돼요"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = Theme.textSecondary
        label.numberOfLines = 0
        return label
    }()
    
    private let progressPublisher: AnyPublisher<Double, Never>
    private let folderProgressPublisher: AnyPublisher<Double, Never>
    private var cancellables = Set<AnyCancellable>()

    init(progress: AnalyzeProgress) {
        self.progress = progress
        
        self.progressPublisher = progress.photoProgress
        self.folderProgressPublisher = progress.folderProgress
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("AlbumAnalysisSheet does not support NSCoding.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.surface
        setupLayout()
        setupBindings()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        photoRow.updateBorderColor()
        albumRow.updateBorderColor()
    }

    // MARK: - Layout

    private func setupLayout() {
        // Circle
        circleBackground.addSubview(progressIndicator)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.snp.makeConstraints { make in
            make.center.equalTo(circleBackground)
        }

        // Location note
        locationNoteView.addSubview(locationIcon)
        locationNoteView.addSubview(locationLabel)
        
        locationIcon.snp.makeConstraints { make in
            make.leading.equalTo(locationNoteView).offset(14)
            make.centerY.equalTo(locationNoteView)
            make.width.height.equalTo(18)
        }
        
        locationLabel.snp.makeConstraints { make in
            make.leading.equalTo(locationIcon.snp.trailing).offset(8)
            make.trailing.equalTo(locationNoteView).offset(-14)
            make.top.bottom.equalTo(locationNoteView).inset(10)
        }

        // Text stack
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 8

        // Row stack
        let rowStack = UIStackView(arrangedSubviews: [photoRow, albumRow])
        rowStack.axis = .vertical
        rowStack.spacing = 10

        // Main stack
        let mainStack = UIStackView(arrangedSubviews: [
            circleBackground,
            textStack,
            rowStack,
            locationNoteView
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 18
        mainStack.alignment = .center
        mainStack.setCustomSpacing(12, after: rowStack)

        view.addSubview(grabberView)
        view.addSubview(mainStack)

        grabberView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(10)
            make.centerX.equalTo(view)
            make.width.equalTo(42)
            make.height.equalTo(5)
        }
        
        circleBackground.snp.makeConstraints { make in
            make.width.height.equalTo(84)
        }
        
        mainStack.snp.makeConstraints { make in
            make.top.equalTo(grabberView.snp.bottom).offset(20)
            make.leading.trailing.equalTo(view).inset(20)
        }
        
        locationNoteView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(mainStack)
        }
        
        rowStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(mainStack)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(24)
        }
    }
    
    private func setupBindings() {
        progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                print("progressPublisher \(progress)")
                self?.photoRow.updateProgress(progress)
            }
            .store(in: &cancellables)
        
        folderProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                print("folderProgressPublisher \(progress)")
                self?.albumRow.updateProgress(progress)
                if progress >= 1.0 {
                    self?.endPage()
                }
            }
            .store(in: &cancellables)
    }
    
    private func endPage() {
        self.onEnd?()
        self.dismiss(animated: true)
    }
}
