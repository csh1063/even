//
//  TabbarViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 4/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Combine
import Domain

enum TabbarViewModelAction {
    case progressSheet(AnalyzeProgress)
}

struct AnalyzeProgress {
    let photoProgress: AnyPublisher<Double, Never>
    let photoCompleted: AnyPublisher<Void, Never>
    let albumProgress: AnyPublisher<Double, Never>
    let albumCompleted: AnyPublisher<Void, Never>
}

@MainActor
public final class TabbarViewModel: BaseViewModel {

    enum Input {
        case analysis
        case reAutoAlbum
        case clear
        case permission
        case showConsent
        case afterConsent
        case showOnboarding
        case afterOnboarding
    }

    public struct Output {
        let photoProgress: AnyPublisher<Double, Never>
        let albumProgress: AnyPublisher<Double, Never>
        let onboarding: AnyPublisher<Bool?, Never>
        let consent: AnyPublisher<Bool?, Never>
        let permission: AnyPublisher<PhotoPermission, Never>
        let isComplete: AnyPublisher<Bool, Never>
    }

    @Published private var progressRatio: Double = 0
    @Published private var autoAlbumProgressRatio: Double = 0
    // progressRatio/autoAlbumProgressRatio는 진행률 바(0~1) 표시용이고, @Published라 구독 시점의
    // 현재값을 항상 리플레이한다 — "완료"라는 확정적 신호는 그거와 별개로 한 번만 쏘는 이벤트로 관리한다
    // (PassthroughSubject는 과거 값을 리플레이하지 않아서, 뒤늦게 구독해도 엉뚱한 값에 걸릴 일이 없다)
    private let photoCompletedSubject = PassthroughSubject<Void, Never>()
    private let albumCompletedSubject = PassthroughSubject<Void, Never>()
    @Published private var isAnalyzing: Bool = false
    @Published private var isComplete: Bool = false
    @Published private var onboarding: Bool?
    @Published private var consent: Bool?
    @Published private var permission: PhotoPermission = .notDetermined

    var onAction: ((TabbarViewModelAction) -> Void)?

    let input = PassthroughSubject<Input, Never>()

    private let permissionUseCase: PermissionUseCase
    private let analysisUseCase: PhotoAnalysisUseCase
    private let autoAlbumUseCase: AutoAlbumUseCase
    private let legacyAccessUseCase: LegacyAccessUseCase

    private var cancellables = Set<AnyCancellable>()
    private var analysisTask: Task<Void, Never>?
    private var lifecycleObservers: [NSObjectProtocol] = []

    init(permissionUseCase: PermissionUseCase,
         analysisUseCase: PhotoAnalysisUseCase,
         autoAlbumUseCase: AutoAlbumUseCase,
         legacyAccessUseCase: LegacyAccessUseCase) {
        self.permissionUseCase = permissionUseCase
        self.analysisUseCase = analysisUseCase
        self.autoAlbumUseCase = autoAlbumUseCase
        self.legacyAccessUseCase = legacyAccessUseCase

        super.init()

        self.bind()
        self.bindLifecycle()

        // 콜드 스타트(앱이 완전히 꺼졌다가 다시 켜진 경우)에도 중단된 분석이 있었는지 확인해 이어간다
        Task { @MainActor in await self.handleWillEnterForeground() }
    }

    deinit {
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    public func transform() -> Output {
        return Output(
            photoProgress: $progressRatio.eraseToAnyPublisher(),
            albumProgress: $autoAlbumProgressRatio.eraseToAnyPublisher(),
            onboarding: $onboarding.eraseToAnyPublisher(),
            consent: $consent.eraseToAnyPublisher(),
            permission: $permission.eraseToAnyPublisher(),
            isComplete: $isComplete.eraseToAnyPublisher()
        )
    }

    func send(_ input: Input) {
        self.input.send(input)
    }

    private func bind() {
        self.input.sink { [weak self] input in
            guard let self else { return }
            Task { @MainActor in await self.handle(input) }
        }
        .store(in: &cancellables)
    }

    private func bindLifecycle() {
        let bg = NotificationCenter.default.addObserver(forName: .appDidEnterBackground, object: nil, queue: .main) { [weak self] _ in
            self?.handleDidEnterBackground()
        }
        let fg = NotificationCenter.default.addObserver(forName: .appWillEnterForeground, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.handleWillEnterForeground() }
        }
        lifecycleObservers = [bg, fg]
    }

    private func handleDidEnterBackground() {
        guard isAnalyzing else { return }
        // 유예시간이 끝나면 진행 중인 분석을 취소하고, 시간 안에 못 끝난 경우를 대비해
        // 시스템이 알아서 이어서 실행해줄 BGProcessingTask를 예약한다.
        BackgroundTaskManager.shared.begin { [weak self] in
            self?.analysisTask?.cancel()
            BackgroundProcessingScheduler.shared.schedule()
        }
    }

    private func handleWillEnterForeground() async {
        BackgroundTaskManager.shared.end()

        guard !isAnalyzing else { return }
        guard (try? await analysisUseCase.isAnalysisInterrupted()) == true else { return }

        // 백그라운드 만료로 중단됐던 분석 — 사용자 확인 알럿 없이 자동으로 이어간다
        self.progressRatio = 0
        self.autoAlbumProgressRatio = 0
        self.onAction?(.progressSheet(self.makeAnalyzeProgress()))
        self.analysisTask = Task { await self.analysis() }
    }

    private func makeAnalyzeProgress() -> AnalyzeProgress {
        AnalyzeProgress(
            photoProgress: $progressRatio.eraseToAnyPublisher(),
            photoCompleted: photoCompletedSubject.eraseToAnyPublisher(),
            albumProgress: $autoAlbumProgressRatio.eraseToAnyPublisher(),
            albumCompleted: albumCompletedSubject.eraseToAnyPublisher()
        )
    }

    private func handle(_ input: Input) async {
        switch input {
        case .showConsent:
            await checkConsent()
        case .afterConsent:
            await consentComplete()
        case .showOnboarding:
            await checkOnboarding()
        case .afterOnboarding:
            await onboardingComplete()
        case .analysis:
            showAlert(
                title: String(localized: "사진 분석", bundle: .module),
                message: String(localized: "iCloud에서 분석 용 사이즈를 받기 위해\n데이터가 소모되요.\nWi-Fi에서 진행하는 걸 권장해요.\n분석 시작할까요?", bundle: .module),
                buttons: [
                    AlertButtonConfig(title: String(localized: "취소", bundle: .module), style: .cancel, action: nil),
                    AlertButtonConfig(title: String(localized: "분석하기", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            // 이전 분석/생성이 에러로 끝난 경우 progressRatio가 1.0에 멈춰있을 수 있어서,
                            // 새 시트가 구독하자마자 (@Published는 구독 시점 현재값을 바로 흘려보냄) "완료"로 보일 수 있다 —
                            // 새로 시작하기 전에 항상 0으로 리셋해서 이 시트는 항상 진짜 0부터 시작하게 한다
                            self.progressRatio = 0
                            self.autoAlbumProgressRatio = 0
                            self.onAction?(.progressSheet(self.makeAnalyzeProgress()))
                            self.analysisTask = Task { await self.analysis() }
                        }
                    }
                ]
            )
        case .reAutoAlbum:
            showAlert(
                title: String(localized: "앨범 재생성", bundle: .module),
                message: String(localized: "앨범들을 삭제 후 다시 생성해요.\n어떤 앨범을 다시 생성할까요?", bundle: .module),
                buttons: [
                    AlertButtonConfig(title: String(localized: "취소", bundle: .module), style: .cancel, action: nil),
                    AlertButtonConfig(title: String(localized: "자동 앨범", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            self.isLoading = true
                            await self.albumClear()
                            self.isLoading = false

                            self.autoAlbumProgressRatio = 0
                            self.onAction?(.progressSheet(self.makeAnalyzeProgress()))

                            // 이 플로우는 사진 분석 없이 앨범 생성만 다시 하므로, 사진 분석 단계는 곧바로 완료 처리한다
                            self.progressRatio = 1.0
                            self.photoCompletedSubject.send(())
                            await self.runAlbumGeneration(fullRegenerate: true)
                        }
                    },
                    AlertButtonConfig(title: String(localized: "날짜 앨범", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            await self.createDateAutoAlbum()
                        }
                    },
                    AlertButtonConfig(title: String(localized: "주소 앨범", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            await self.createLocationAutoAlbum()
                        }
                    },
                    AlertButtonConfig(title: String(localized: "카테고리 앨범", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            await self.createCategoryAutoAlbum()
                        }
                    },
                    AlertButtonConfig(title: String(localized: "얼굴 앨범", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            await self.createFaceAutoAlbum()
                        }
                    },
                    AlertButtonConfig(title: String(localized: "동물 앨범", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            await self.createAnimalAutoAlbum()
                        }
                    },
                    AlertButtonConfig(title: String(localized: "여행 앨범", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            await self.createTravelAutoAlbum()
                        }
                    },
                    AlertButtonConfig(title: String(localized: "비슷한 사진 앨범", bundle: .module), style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            await self.createSimilarAutoAlbum()
                        }
                    }
                ]
            )
        case .clear:
            showAlert(
                title: String(localized: "초기화", bundle: .module),
                message: String(localized: "저장된 사진 및 앨범을 모두 삭제할까요?", bundle: .module),
                buttons: [
                    AlertButtonConfig(title: String(localized: "취소", bundle: .module), style: .cancel, action: nil),
                    AlertButtonConfig(title: String(localized: "삭제", bundle: .module), style: .destructive) { [weak self] in
                        Task {
                            LoadingManager.shared.show(allowDismiss: false)
                            await self?.clear()
                            LoadingManager.shared.hide()
                        }
                    }
                ]
            )
        case .permission:
            await checkPermission()
        }
    }

    // MARK: - 분석 + 앨범 생성 통합 플로우

    private func analysis() async {
        guard !isAnalyzing else { return }
        self.isAnalyzing = true
        try? await analysisUseCase.markAnalysisStarted()
        AnalysisCompletionNotifier.requestAuthorizationIfNeeded()
        LiveActivityManager.shared.start()

        let startedAt = Date()
        debugLog("⏱️ [분석] 시작: \(startedAt)")

        do {
            for try await progress in analysisUseCase.analysis() {
                if Task.isCancelled { throw CancellationError() }
                switch progress.state {
                case .progress(let ratio):
                    self.progressRatio = ratio
                    await LiveActivityManager.shared.updateCombined(photoRatio: ratio, albumRatio: 0)
                case .completed:
                    self.progressRatio = 1.0
                case .unavailable:
                    break
                }
            }
            self.progressRatio = 1.0
            self.photoCompletedSubject.send(())
            try? await legacyAccessUseCase.markLegacyFreeAccess()
            try? await analysisUseCase.markAnalysisFinished()

            // Live Activity는 여기서 끝내지 않는다 — 앨범 생성까지 마쳐야 진짜 100%다.
            await runAlbumGeneration()
            AnalysisCompletionNotifier.notifyIfBackgrounded()
        } catch is CancellationError {
            // 백그라운드 유예시간 만료로 인한 정상적인 중단 — "완료"로 위장하지 않는다.
            // analysisInProgress 플래그는 true로 남겨두어 다음 포그라운드 복귀 시 자동 재개된다.
            // Live Activity는 끝내지 않고 마지막 진행률에서 멈춰있게 둔다 — BGProcessingTask가 이어서 갱신한다.
            debugLog("⏸️ [분석] 백그라운드 만료로 중단 — 다음 포그라운드 복귀 시 자동 재개 예정")
        } catch {
            try? await analysisUseCase.markAnalysisFinished()
            await LiveActivityManager.shared.end()
            self.progressRatio = 1.0
            self.autoAlbumProgressRatio = 1.0
            self.photoCompletedSubject.send(())
            self.albumCompletedSubject.send(())
        }
        self.isAnalyzing = false
        BackgroundTaskManager.shared.end()

        let finishedAt = Date()
        let elapsedMinutes = finishedAt.timeIntervalSince(startedAt) / 60
        debugLog("⏱️ [분석] 종료: \(finishedAt) — 총 \(String(format: "%.1f", elapsedMinutes))분 소요")
    }

    private func runAlbumGeneration(fullRegenerate: Bool = false) async {
        self.isComplete = false
        do {
            for try await progress in autoAlbumUseCase.generateAllAlbums(fullRegenerate: fullRegenerate) {
                self.autoAlbumProgressRatio = progress.ratio
                await LiveActivityManager.shared.updateCombined(photoRatio: self.progressRatio, albumRatio: progress.ratio)
                if case .completed = progress.step {
                    self.autoAlbumProgressRatio = 1.0
                    self.isComplete = true
                    self.albumCompletedSubject.send(())
                    self.endAllProcess()
                    await LiveActivityManager.shared.end()
                }
            }
        } catch {
            self.autoAlbumProgressRatio = 1.0
            self.isComplete = true
            self.albumCompletedSubject.send(())
            await LiveActivityManager.shared.end()
        }
    }

    // MARK: - 개별 앨범 (재)생성

    private func createTravelAutoAlbum() async {
        self.isComplete = false
        do {
            self.isLoading = true

            for try await progress in autoAlbumUseCase.createTravelAutoAlbum() {
                if case .completed = progress.step {
                    self.isLoading = false
                    self.isComplete = true
                }
            }
        } catch {
            self.isLoading = false
            self.isComplete = true
        }
    }

    private func createSimilarAutoAlbum() async {
        self.isComplete = false
        do {
            self.isLoading = true
            try await autoAlbumUseCase.createSimilarAlbum()
            self.isLoading = false
            self.isComplete = true
        } catch {
            self.isLoading = false
            self.isComplete = true
        }
    }

    private func createDateAutoAlbum() async {
        self.isComplete = false
        do {
            self.isLoading = true
            try await autoAlbumUseCase.createDateAlbums()
            self.isLoading = false
            self.isComplete = true
        } catch {
            self.isLoading = false
            self.isComplete = true
        }
    }

    private func createLocationAutoAlbum() async {
        self.isComplete = false
        do {
            self.isLoading = true
            try await autoAlbumUseCase.createLocationAlbums()
            self.isLoading = false
            self.isComplete = true
        } catch {
            self.isLoading = false
            self.isComplete = true
        }
    }

    private func createCategoryAutoAlbum() async {
        self.isComplete = false
        do {
            self.isLoading = true
            try await autoAlbumUseCase.createCategoryAlbums()
            self.isLoading = false
            self.isComplete = true
        } catch {
            self.isLoading = false
            self.isComplete = true
        }
    }

    private func createFaceAutoAlbum() async {
        self.isComplete = false
        do {
            self.isLoading = true
            try await autoAlbumUseCase.createFaceAlbums()
            self.isLoading = false
            self.isComplete = true
        } catch {
            self.isLoading = false
            self.isComplete = true
        }
    }

    private func createAnimalAutoAlbum() async {
        self.isComplete = false
        do {
            self.isLoading = true
            try await autoAlbumUseCase.createAnimalAlbums()
            self.isLoading = false
            self.isComplete = true
        } catch {
            self.isLoading = false
            self.isComplete = true
        }
    }

    private func clear() async {
        do {
            self.isComplete = false
            try await self.autoAlbumUseCase.deletePhotos()
            self.isComplete = true
        } catch {
            debugLog("error: \(error.localizedDescription)")
        }
    }

    private func albumClear() async {
        do {
            self.isComplete = false
            try await self.autoAlbumUseCase.deleteAutoAlbums()
            self.isComplete = true
        } catch {
            debugLog("error: \(error.localizedDescription)")
        }
    }

    private func checkConsent() async {
        do {
            self.consent = try await permissionUseCase.showConsent()
        } catch {
            debugLog("checkConsent failed")
        }
    }

    private func consentComplete() async {
        do {
            try await permissionUseCase.completeConsent()
        } catch {
            debugLog("consentComplete fail")
        }
    }

    private func checkOnboarding() async {
        do {
            self.onboarding = try await permissionUseCase.showOnboarding()
        } catch {
            debugLog("checkConsent failed")
        }
    }

    private func onboardingComplete() async {
        do {
            try await permissionUseCase.completeOnboarding()
        } catch {
            debugLog("consentComplete fail")
        }
    }

    private func checkPermission() async {
        do {
            self.permission = try await permissionUseCase.checkPermission()
        } catch {
            debugLog("checkPermission failed")
        }
    }

    private func endAllProcess() {
        self.progressRatio = 0.0
        self.autoAlbumProgressRatio = 0.0
    }
}
