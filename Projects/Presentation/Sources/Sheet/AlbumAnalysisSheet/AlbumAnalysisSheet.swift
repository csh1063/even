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

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "icon", in: .module, with: nil))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "새 앨범 만드는 중", bundle: .module)
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = Theme.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "사진과 얼굴, 위치를 분석하고\n관련 앨범을 만들고 있어요\n완료될 때까지 조금만 기다려주세요", bundle: .module)
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = Theme.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let photoRow = ProgressRow(icon: "photo.badge.plus", title: String(localized: "사진 분석 중", bundle: .module))
    private let albumRow = ProgressRow(icon: "square.stack.3d.up.fill", title: String(localized: "앨범 생성 중", bundle: .module))

    private let progressPublisher: AnyPublisher<Double, Never>
    private let photoCompletedPublisher: AnyPublisher<Void, Never>
    private let albumProgressPublisher: AnyPublisher<Double, Never>
    private let albumCompletedPublisher: AnyPublisher<Void, Never>
    private var cancellables = Set<AnyCancellable>()
    private var didStartAlbumGeneration = false

    init(progress: AnalyzeProgress) {
        self.progress = progress

        self.progressPublisher = progress.photoProgress
        self.photoCompletedPublisher = progress.photoCompleted
        self.albumProgressPublisher = progress.albumProgress
        self.albumCompletedPublisher = progress.albumCompleted

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
        circleBackground.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.center.equalTo(circleBackground)
            make.width.height.equalTo(48)
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
            rowStack
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

        rowStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(mainStack)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(24)
        }
    }

    private func setupBindings() {
        // 사진 분석이 끝나기 전까지는 앨범 생성은 아직 시작 전이니 "대기" 상태로 보여준다
        photoRow.startSpinner()
        albumRow.setTitle(String(localized: "앨범 생성 대기", bundle: .module))
        albumRow.stopSpinner()

        // progress 값(0~1)은 오직 진행률 바 표시용 — @Published라 구독 시점 현재값을 리플레이하기 때문에
        // "완료"라는 확정적인 상태 전환은 이 값으로 추론하지 않고, 아래 photoCompleted/albumCompleted
        // 이벤트(PassthroughSubject라 리플레이 없음)로만 판단한다
        progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.photoRow.updateProgress(progress)
            }
            .store(in: &cancellables)

        albumProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.albumRow.updateProgress(progress)
            }
            .store(in: &cancellables)

        photoCompletedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.startAlbumGenerationIfNeeded()
            }
            .store(in: &cancellables)

        albumCompletedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                self.startAlbumGenerationIfNeeded()
                self.albumRow.updateProgress(1.0)
                self.albumRow.setTitle(String(localized: "앨범 생성 완료", bundle: .module))
                self.albumRow.stopSpinner()
                self.endPage()
            }
            .store(in: &cancellables)
    }

    private func startAlbumGenerationIfNeeded() {
        guard !didStartAlbumGeneration else { return }
        didStartAlbumGeneration = true

        photoRow.setTitle(String(localized: "사진 분석 완료", bundle: .module))
        photoRow.stopSpinner()

        albumRow.setTitle(String(localized: "앨범 생성 중", bundle: .module))
        albumRow.startSpinner()
    }

    private func endPage() {
        self.dismiss(animated: true)
    }
}
