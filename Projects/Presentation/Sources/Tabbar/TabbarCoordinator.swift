//
//  TabbarCoordinator.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

@MainActor
final class TabbarCoordinator: BaseCoordinator {

    private let container: TabbarDIContainer
    private var tabbarViewController: TabbarViewController?
    private let window: UIWindow

    private var cancellables = Set<AnyCancellable>()

    /// 진행 상태 표시 3단계: 1(시트) → 2(미니위젯) → 3(탭바 옆 배지). currentTier == nil은 "지금 진행
    /// 중인 분석이 없다"는 뜻(완료해서 완전히 치워졌거나, 애초에 시작 전).
    private enum ProgressTier {
        case sheet
        case mini
        case badge
    }
    private var currentTier: ProgressTier?
    private var currentAnalyzeProgress: AnalyzeProgress?
    private var isAnalysisComplete = false

    public init(container: TabbarDIContainer, window: UIWindow) {
        self.container = container
        self.window = window

        super.init()
    }

    public override func start() {

        let viewModel = container.makeTabbarViewModel()
        viewModel.onAction = { [weak self] type in
            switch type {
            case .progressSheet(let progress):
                self?.startAnalysisFlow(progress: progress)
            }
        }

        bindAlert(from: viewModel)

        self.tabbarViewController = TabbarViewController(viewModel: viewModel)
        // 탭 전환도 "사용자가 화면을 이동했다" 신호 — 미니위젯(2단계)이 떠 있는 동안 탭을 바꾸면
        // 배지(3단계)로 축소한다.
        self.tabbarViewController?.onTabSelected = { [weak self] in self?.handleUserDidNavigate() }

        let photoCoordinator = makePhotoLibraryCoordinator(viewModel: viewModel)
        let albumCoordinator = makeAlbumCoordinator(viewModel: viewModel)
        let myPageCoordinator = makeMyPageCoordinator(viewModel: viewModel)
        [photoCoordinator, albumCoordinator, myPageCoordinator].forEach {
            $0.hideTabBar = { [weak self] in
                self?.tabbarViewController?.hideTabbar()
            }

            $0.showTabBar = { [weak self] in
                self?.tabbarViewController?.showTabbar()
            }

            // 각 탭의 네비게이션 컨트롤러는 하나씩이라(자식 코디네이터도 전부 같은 컨트롤러에 push),
            // 이 델리게이트 하나로 그 탭 안의 모든 화면 이동(상세/모두보기 등)을 다 잡아낸다.
            $0.onNavigate = { [weak self] in self?.handleUserDidNavigate() }
        }
        let photo = photoCoordinator.startAndReturn()
        let album = albumCoordinator.startAndReturn()
        let myPage = myPageCoordinator.startAndReturn()

        self.tabbarViewController?.setTabBarItem("photo.on.rectangle.angled", vc: photo, title: String(localized: "사진첩", bundle: .module))
        self.tabbarViewController?.setTabBarItem("square.stack", vc: album, title: String(localized: "앨범", bundle: .module))
        self.tabbarViewController?.setTabBarItem("gearshape", vc: myPage, title: String(localized: "설정", bundle: .module))

        let controllers = [photo,
                           album,
                           myPage]

        self.tabbarViewController?.setViewControllers(controllers)

        window.rootViewController = self.tabbarViewController
        window.makeKeyAndVisible()
    }

    private func makePhotoLibraryCoordinator(viewModel: TabbarViewModel) -> PhotoLibraryCoordinator {
        let diContainer = container.makePhotoLibraryDIContainer()
        return PhotoLibraryCoordinator(diContainer: diContainer, tabbarViewModel: viewModel)
    }

    private func makeAlbumCoordinator(viewModel: TabbarViewModel) -> AlbumCoordinator {
        let diContainer = container.makeAlbumDIContainer()
        return AlbumCoordinator(diContainer: diContainer, tabbarViewModel: viewModel)
    }

    private func makeMyPageCoordinator(viewModel: TabbarViewModel) -> MyPageCoordinator {
        let diContainer = container.makeMyPageDIContainer()
        return MyPageCoordinator(diContainer: diContainer, tabbarViewModel: viewModel)
    }

    // MARK: - 진행 상태 3단계 오케스트레이션

    private func startAnalysisFlow(progress: AnalyzeProgress) {
        currentAnalyzeProgress = progress
        isAnalysisComplete = false
        subscribeCompletion(progress: progress)
        currentTier = .sheet
        presentSheet(progress: progress)
    }

    private func presentSheet(progress: AnalyzeProgress) {
        // 같은 progress를 보여주는 플로팅 미니 진행률/배지가 이미 떠 있다면(최소화 상태에서 다시
        // 시트를 열게 되는 경우) 중복 표시되지 않도록 먼저 치운다.
        AnalysisProgressManager.shared.hide()
        AnalysisBadgeManager.shared.hide()
        tabbarViewController?.setBadgeModeActive(false)

        let sheet = AlbumAnalysisSheet(progress: progress)
        sheet.isModalInPresentation = true
        if let presentation = sheet.sheetPresentationController {
            // .large()도 미리 등록해둬야 "자세히" 펼쳤을 때 시트가 그쪽으로 전환할 수 있다 —
            // 시작은 항상 .medium()이고, AlbumAnalysisSheet가 자세히 펼침/접힘에 맞춰 전환한다.
            presentation.detents = [.medium(), .large()]
            presentation.selectedDetentIdentifier = .medium
            presentation.preferredCornerRadius = 28
        }
        // 사용자가 명시적으로 최소화 버튼을 눌러 시트를 닫으면(스와이프/탭-아웃은 여전히 막혀있음),
        // 진행 중이던 분석/앨범생성 진행률을 그대로 물려받는 플로팅 미니 진행률(2단계)로 대체한다 —
        // 분석 자체는 계속 진행된다.
        sheet.onMinimize = { [weak self] in
            self?.enterMiniTier()
        }

        tabbarViewController?.present(sheet, animated: true)
    }

    /// 2단계 — 탭바 위 플로팅 미니 진행률. 탭하면 1단계(시트)로 복귀한다.
    private func enterMiniTier() {
        guard let progress = currentAnalyzeProgress else { return }
        currentTier = .mini
        AnalysisBadgeManager.shared.hide()
        tabbarViewController?.setBadgeModeActive(false)

        AnalysisProgressManager.shared.show(
            locationProgress: progress.photoProgress,
            albumProgress: progress.albumProgress,
            onTap: { [weak self] in
                // 슬라이드-아웃 애니메이션이 실제로 끝난 뒤에 시트를 띄운다 — 바로 present하면
                // 위젯이 사라지는 게 아니라 새로 뜬 시트에 그냥 가려져서 애니메이션이 안 보였다.
                AnalysisProgressManager.shared.hide(delay: 0) {
                    self?.currentTier = .sheet
                    self?.presentSheet(progress: progress)
                }
            }
        )
    }

    /// 3단계 — 탭바 옆 활동 배지. 2단계 상태에서 사용자가 어디로든 화면을 이동하면(탭 전환/상세
    /// 진입 등) 여기로 축소된다. 이때만 탭바가 왼쪽으로 슬라이드돼서 배지 자리를 내준다.
    private func enterBadgeTier() {
        guard currentAnalyzeProgress != nil, !isAnalysisComplete else { return }
        currentTier = .badge
        AnalysisProgressManager.shared.hide()
        tabbarViewController?.setBadgeModeActive(true)

        AnalysisBadgeManager.shared.show(onTap: { [weak self] in
            self?.handleBadgeTap()
        })
    }

    /// 미니위젯(2단계)이 떠 있는 동안에만 의미가 있다 — 시트가 떠 있을 땐 모달이라 애초에 다른 화면으로
    /// 이동할 수 없고, 이미 배지(3단계)인데 또 이동해도 그대로 배지 유지면 된다.
    private func handleUserDidNavigate() {
        guard currentTier == .mini else { return }
        enterBadgeTier()
    }

    /// 배지를 탭했을 때 — 아직 진행 중이면 미니위젯(2단계)으로 복귀, 이미 완료 상태("완료" 텍스트로
    /// 바뀐 뒤)라면 그냥 치우고 탭바를 원래(가운데) 위치로 되돌린다.
    private func handleBadgeTap() {
        if isAnalysisComplete {
            AnalysisBadgeManager.shared.hide()
            tabbarViewController?.setBadgeModeActive(false)
            currentTier = nil
            currentAnalyzeProgress = nil
        } else {
            enterMiniTier()
        }
    }

    private func subscribeCompletion(progress: AnalyzeProgress) {
        progress.albumCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                self.isAnalysisComplete = true
                switch self.currentTier {
                case .badge:
                    // 배지 상태에서 완료되면 바로 사라지지 않고 "완료" 텍스트로 바뀐다 — 사용자가
                    // 탭해야(handleBadgeTap) 사라지면서 탭바가 가운데로 복귀한다.
                    AnalysisBadgeManager.shared.showCompleted()
                case .sheet, .mini, .none:
                    // 시트는 스스로 dismiss(AlbumAnalysisSheet.endPage), 미니위젯은 스스로 hide
                    // (MiniProgressView가 progress>=1.0일 때 자동으로 처리) — 여기선 상태만 정리.
                    self.currentTier = nil
                    self.currentAnalyzeProgress = nil
                }
            }
            .store(in: &cancellables)
    }
}
