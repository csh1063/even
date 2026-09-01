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
    /// 사용자가 명시적으로 최소화 버튼을 눌렀을 때만 불린다 — 스와이프/탭-아웃으로는 안 닫히므로
    /// (isModalInPresentation = true, 분석 중 리셋 화면 이동 방지 목적) 이 콜백이 유일한 "닫힘" 신호다.
    var onMinimize: (() -> Void)?

    private let minimizeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = Theme.textSecondary
        return button
    }()

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

    // MARK: - 자세히 체크리스트

    private let dateCheckItem = ChecklistItemRow(icon: "calendar", title: String(localized: "날짜 확인", bundle: .module))
    private let addressConvertItem = ChecklistItemRow(icon: "location.fill", title: String(localized: "좌표를 주소로", bundle: .module))
    private let travelSpotItem = ChecklistItemRow(icon: "suitcase.fill", title: String(localized: "여행지 확인", bundle: .module))
    private let photoLabelItem = ChecklistItemRow(icon: "photo.fill", title: String(localized: "사진 분석", bundle: .module))
    private let faceAnalysisItem = ChecklistItemRow(icon: "person.crop.circle", title: String(localized: "얼굴 분석", bundle: .module))
    private let animalAnalysisItem = ChecklistItemRow(icon: "pawprint.fill", title: String(localized: "반려동물 분석", bundle: .module))
    private let similarItem = ChecklistItemRow(icon: "square.on.square", title: String(localized: "비슷한 사진", bundle: .module))

    // 날짜 앨범은 위 "날짜 확인"과 내용이 겹쳐서 목록에서는 뺀다 — 생성 로직 자체는 그대로 두고
    // (AutoAlbumUseCase.createDateAlbumsEarly 등 안 건드림) 이 화면에 노출하는 행만 주석 처리.
    // private let dateAlbumItem = ChecklistItemRow(icon: "calendar", title: String(localized: "날짜 앨범", bundle: .module))
    private let travelAlbumItem = ChecklistItemRow(icon: "suitcase.fill", title: String(localized: "여행 앨범", bundle: .module))
    private let regionAlbumItem = ChecklistItemRow(icon: "mappin.and.ellipse", title: String(localized: "지역 앨범", bundle: .module))
    private let categoryAlbumItem = ChecklistItemRow(icon: "square.grid.2x2.fill", title: String(localized: "카테고리 앨범", bundle: .module))
    private let faceAlbumItem = ChecklistItemRow(icon: "person.crop.circle", title: String(localized: "얼굴 앨범", bundle: .module))
    private let animalAlbumItem = ChecklistItemRow(icon: "pawprint.fill", title: String(localized: "반려동물 앨범", bundle: .module))
    private let duplicateAlbumItem = ChecklistItemRow(icon: "square.on.square", title: String(localized: "중복 사진 앨범", bundle: .module))

    private let photoChecklistContainer = UIStackView()
    private let albumChecklistContainer = UIStackView()
    private var photoChecklistWrapper: UIView!
    private var albumChecklistWrapper: UIView!
    private var isPhotoChecklistExpanded = false
    private var isAlbumChecklistExpanded = false

    private let scrollView = UIScrollView()

    private let progressPublisher: AnyPublisher<Double, Never>
    private let photoCompletedPublisher: AnyPublisher<Void, Never>
    private let albumProgressPublisher: AnyPublisher<Double, Never>
    private let albumCompletedPublisher: AnyPublisher<Void, Never>
    private var cancellables = Set<AnyCancellable>()

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
        minimizeButton.addTarget(self, action: #selector(minimizeTapped), for: .touchUpInside)
    }

    @objc private func minimizeTapped() {
        onMinimize?()
        dismiss(animated: true)
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

        // 자세히 체크리스트 — 각각 얇은 구분선 + 세로 스택
        [photoChecklistContainer, albumChecklistContainer].forEach {
            $0.axis = .vertical
            $0.spacing = 6
        }
        [dateCheckItem, addressConvertItem, travelSpotItem, photoLabelItem, faceAnalysisItem, animalAnalysisItem, similarItem]
            .forEach { photoChecklistContainer.addArrangedSubview($0) }
        [travelAlbumItem, regionAlbumItem, categoryAlbumItem, faceAlbumItem, animalAlbumItem, duplicateAlbumItem]
            .forEach { albumChecklistContainer.addArrangedSubview($0) }

        photoChecklistWrapper = wrapWithTopDivider(photoChecklistContainer)
        albumChecklistWrapper = wrapWithTopDivider(albumChecklistContainer)
        // 펼침 여부는 이 wrapper의 isHidden으로만 제어한다 — group 스택의 arranged subview라 hidden일
        // 때 레이아웃 공간 자체가 사라진다(내부 컨테이너를 숨기면 wrapper 높이가 안 줄어드는 문제가 있었음).
        photoChecklistWrapper.isHidden = true
        albumChecklistWrapper.isHidden = true

        let photoGroup = UIStackView(arrangedSubviews: [photoRow, photoChecklistWrapper])
        photoGroup.axis = .vertical
        photoGroup.spacing = 10

        let albumGroup = UIStackView(arrangedSubviews: [albumRow, albumChecklistWrapper])
        albumGroup.axis = .vertical
        albumGroup.spacing = 10

        // Row stack
        let rowStack = UIStackView(arrangedSubviews: [photoGroup, albumGroup])
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
        view.addSubview(minimizeButton)
        view.addSubview(scrollView)
        scrollView.addSubview(mainStack)

        grabberView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(10)
            make.centerX.equalTo(view)
            make.width.equalTo(42)
            make.height.equalTo(5)
        }

        minimizeButton.snp.makeConstraints { make in
            make.top.equalTo(view).offset(16)
            make.trailing.equalTo(view).inset(20)
            make.width.height.equalTo(28)
        }

        circleBackground.snp.makeConstraints { make in
            make.width.height.equalTo(84)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(grabberView.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(view)
        }

        mainStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(10)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-24)
            make.leading.trailing.equalTo(view).inset(20)
        }

        rowStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(mainStack)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view).inset(24)
        }
    }

    /// 체크리스트 컨테이너 위에 얇은 구분선을 붙인 wrapper를 만들어 반환한다. 펼침/접힘은 반드시 이
    /// wrapper의 isHidden으로만 제어해야 한다 — 컨테이너 자신을 숨기면 wrapper는 그대로 남아있는
    /// 자신의 제약(divider~content~bottom) 때문에 높이가 안 줄어들어 접힌 상태에서도 빈 공간+구분선이
    /// 남는 문제가 생긴다.
    private func wrapWithTopDivider(_ content: UIStackView) -> UIView {
        let divider = UIView()
        divider.backgroundColor = Theme.strokeSoft

        let wrapper = UIView()
        wrapper.addSubview(divider)
        wrapper.addSubview(content)

        divider.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(wrapper)
            make.height.equalTo(1)
        }
        content.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(wrapper)
        }
        return wrapper
    }

    // MARK: - Bindings

    private func setupBindings() {
        // 사진 분석과 앨범 생성이 순차가 아니라 2트랙(주소/라벨)으로 동시에 진행되고, 앨범 생성도
        // 각 트랙이 끝나는 대로 바로 시작되므로 두 로딩 인디케이터를 처음부터 같이 돌린다.
        photoRow.startSpinner()
        albumRow.setTitle(String(localized: "앨범 생성 중", bundle: .module))
        albumRow.startSpinner()

        photoRow.onToggleDetail = { [weak self] in self?.toggleChecklist(isPhoto: true) }
        albumRow.onToggleDetail = { [weak self] in self?.toggleChecklist(isPhoto: false) }

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
                guard let self else { return }
                self.photoRow.updateProgress(1.0)
                self.photoRow.setTitle(String(localized: "사진 분석 완료", bundle: .module))
                self.photoRow.stopSpinner()
            }
            .store(in: &cancellables)

        albumCompletedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                self.albumRow.updateProgress(1.0)
                self.albumRow.setTitle(String(localized: "앨범 생성 완료", bundle: .module))
                self.albumRow.stopSpinner()
                self.endPage()
            }
            .store(in: &cancellables)

        bindChecklistItem(dateCheckItem, to: progress.analysisChecklist.dateCheck)
        bindChecklistItem(addressConvertItem, to: progress.analysisChecklist.addressConvert)
        bindChecklistItem(travelSpotItem, to: progress.analysisChecklist.travelSpot)
        bindChecklistItem(photoLabelItem, to: progress.analysisChecklist.photoLabel)
        bindChecklistItem(faceAnalysisItem, to: progress.analysisChecklist.face)
        bindChecklistItem(animalAnalysisItem, to: progress.analysisChecklist.animal)
        bindChecklistItem(similarItem, to: progress.analysisChecklist.similar)

        bindChecklistItem(travelAlbumItem, to: progress.albumChecklist.travel)
        bindChecklistItem(regionAlbumItem, to: progress.albumChecklist.region)
        bindChecklistItem(categoryAlbumItem, to: progress.albumChecklist.category)
        bindChecklistItem(faceAlbumItem, to: progress.albumChecklist.face)
        bindChecklistItem(animalAlbumItem, to: progress.albumChecklist.animal)
        bindChecklistItem(duplicateAlbumItem, to: progress.albumChecklist.duplicate)
    }

    private func bindChecklistItem(_ item: ChecklistItemRow, to publisher: AnyPublisher<Double, Never>) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { ratio in
                let state: ChecklistItemRow.State = ratio <= 0 ? .waiting : (ratio >= 1 ? .done : .inProgress)
                item.setState(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - 자세히 아코디언

    /// 한쪽을 펼치면 다른 쪽은 자동으로 접힌다 — 시트 안에서 동시에 두 체크리스트가 다 펼쳐져 있으면
    /// 너무 길어지고 산만해지기 때문. 펼쳐진 게 하나라도 있으면 detent를 .large()로 넓혀서 7~6줄짜리
    /// 목록이 잘리지 않게 하고, 다 접히면 원래 .medium()으로 되돌린다.
    private func toggleChecklist(isPhoto: Bool) {
        let willExpandPhoto = isPhoto ? !isPhotoChecklistExpanded : false
        let willExpandAlbum = isPhoto ? false : !isAlbumChecklistExpanded
        isPhotoChecklistExpanded = willExpandPhoto
        isAlbumChecklistExpanded = willExpandAlbum

        photoRow.setDetailExpanded(willExpandPhoto)
        albumRow.setDetailExpanded(willExpandAlbum)

        if let sheetPresentation = sheetPresentationController {
            let anyExpanded = willExpandPhoto || willExpandAlbum
            sheetPresentation.animateChanges {
                sheetPresentation.selectedDetentIdentifier = anyExpanded ? .large : .medium
            }
        }

        UIView.animate(withDuration: 0.3) {
            self.photoChecklistWrapper.isHidden = !willExpandPhoto
            self.albumChecklistWrapper.isHidden = !willExpandAlbum
            self.view.layoutIfNeeded()
        }
    }

    private func endPage() {
        self.dismiss(animated: true)
    }
}
