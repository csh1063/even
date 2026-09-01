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
    let analysisChecklist: AnalysisChecklistProgress
    let albumChecklist: AlbumChecklistProgress
}

/// 시트 "자세히" 목록 — 사진 분석 쪽 7항목. 얼굴/반려동물/사진(라벨)은 실제로는 한 파이프라인에서
/// 같이 처리돼서 따로 뽑을 신호가 없다 — 라벨 스트림 진행률(photoLabel)을 셋이 공유해서 보여준다.
/// 여행지 확인도 마찬가지로 여행 앨범(travelProgress) 신호를 그대로 재사용한다.
struct AnalysisChecklistProgress {
    let dateCheck: AnyPublisher<Double, Never>
    let addressConvert: AnyPublisher<Double, Never>
    let travelSpot: AnyPublisher<Double, Never>
    let photoLabel: AnyPublisher<Double, Never>
    let face: AnyPublisher<Double, Never>
    let animal: AnyPublisher<Double, Never>
    let similar: AnyPublisher<Double, Never>
}

/// 시트 "자세히" 목록 — 앨범 생성 쪽 6항목(날짜 앨범은 위 dateCheck와 중복돼서 목록에서 뺌).
struct AlbumChecklistProgress {
    let travel: AnyPublisher<Double, Never>
    let region: AnyPublisher<Double, Never>
    let category: AnyPublisher<Double, Never>
    let face: AnyPublisher<Double, Never>
    let animal: AnyPublisher<Double, Never>
    let duplicate: AnyPublisher<Double, Never>
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

    // MARK: - 진행률 컴포넌트 (사용자 확정 가중치)
    //
    // 각 항목은 자기 몫만큼의 가중치를 가진 독립적인 0~1 값이고, progressRatio/autoAlbumProgressRatio는
    // 이 값들을 가중합해서 매번 다시 계산한다("실행 순서"가 아니라 "가중치"만 정해져 있는 구조라, 두
    // 항목이 동시에 끝나면 둘 다 그대로 반영되고, 어느 순서로 끝나든 상관없다).
    //
    // 사진 분석: 날짜 5% + (지오코딩+라벨/임베딩 결합) 85% + 중복사진 탐지(임베딩 추출+비교) 10%
    // @Published인 이유: 요약 진행률 계산뿐 아니라 시트 "자세히" 체크리스트에도 각자 그대로 노출되기
    // 때문 — 아래 makeAnalyzeProgress()에서 $프로퍼티로 개별 publisher를 만든다.
    @Published private var dateProgress: Double = 0
    @Published private var addressProgress: Double = 0
    @Published private var streamProgress: Double = 0
    @Published private var dupDetectProgress: Double = 0
    // 앨범 생성: 여행 30% + 지역 10% + 얼굴 15%/동물 15% + 여행자연결 10% + 카테고리 10% + 중복앨범저장 10%
    @Published private var travelProgress: Double = 0
    @Published private var regionProgress: Double = 0
    @Published private var faceProgress: Double = 0
    @Published private var animalProgress: Double = 0
    private var travelerLinkProgress: Double = 0
    @Published private var categoryProgress: Double = 0
    @Published private var dupSaveProgress: Double = 0

    private func resetProgressComponents() {
        dateProgress = 0; addressProgress = 0; streamProgress = 0; dupDetectProgress = 0
        travelProgress = 0; regionProgress = 0; faceProgress = 0; animalProgress = 0
        travelerLinkProgress = 0; categoryProgress = 0; dupSaveProgress = 0
    }

    private func recomputePhotoProgress() {
        progressRatio = dateProgress * 0.05 + streamProgress * 0.85 + dupDetectProgress * 0.1
    }

    private func recomputeAlbumProgress() {
        autoAlbumProgressRatio = travelProgress * 0.3
            + regionProgress * 0.1
            + faceProgress * 0.15
            + animalProgress * 0.15
            + travelerLinkProgress * 0.1
            + categoryProgress * 0.1
            + dupSaveProgress * 0.1
    }
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

    private func makeAnalyzeProgress() -> AnalyzeProgress {
        AnalyzeProgress(
            photoProgress: $progressRatio.eraseToAnyPublisher(),
            photoCompleted: photoCompletedSubject.eraseToAnyPublisher(),
            albumProgress: $autoAlbumProgressRatio.eraseToAnyPublisher(),
            albumCompleted: albumCompletedSubject.eraseToAnyPublisher(),
            analysisChecklist: AnalysisChecklistProgress(
                dateCheck: $dateProgress.eraseToAnyPublisher(),
                addressConvert: $addressProgress.eraseToAnyPublisher(),
                travelSpot: $travelProgress.eraseToAnyPublisher(),
                photoLabel: $streamProgress.eraseToAnyPublisher(),
                face: $faceProgress.eraseToAnyPublisher(),
                animal: $animalProgress.eraseToAnyPublisher(),
                similar: $dupDetectProgress.eraseToAnyPublisher()
            ),
            albumChecklist: AlbumChecklistProgress(
                travel: $travelProgress.eraseToAnyPublisher(),
                region: $regionProgress.eraseToAnyPublisher(),
                category: $categoryProgress.eraseToAnyPublisher(),
                face: $faceProgress.eraseToAnyPublisher(),
                animal: $animalProgress.eraseToAnyPublisher(),
                duplicate: $dupSaveProgress.eraseToAnyPublisher()
            )
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
                            await self.analysis()
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
            guard !isAnalyzing else {
                showAlert(
                    title: String(localized: "삭제할 수 없어요", bundle: .module),
                    message: String(localized: "분석이 진행 중일 때는 사진과 앨범을 삭제할 수 없어요\n분석이 끝난 뒤 다시 시도해주세요", bundle: .module),
                    buttons: [
                        AlertButtonConfig(title: String(localized: "확인", bundle: .module), style: .default, action: nil)
                    ]
                )
                return
            }
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

    /// 분석이 진행되는 동안(전체가 끝나길 기다리지 않고) 각 데이터가 준비되는 대로 관련 앨범을 바로
    /// 생성한다. 두 트랙이 각자 필요한 데이터만 준비되면 바로 다음 단계로 넘어간다 — 기다릴 필요 없는
    /// 단계를 억지로 뒤에 묶어두지 않는다:
    /// - 주소 트랙: 지오코딩 완료 → 여행 앨범 → 지역 앨범(주소만 있으면 됨, 라벨 안 씀)
    /// - 라벨 트랙: 라벨+임베딩 완료 → 카테고리 앨범(라벨만 있으면 됨) → 얼굴/동물 앨범 → 중복사진 탐지
    ///   (얼굴/동물·중복탐지는 카테고리보다 오래 걸려서 카테고리를 먼저 끝내는 게 이득)
    ///
    /// 진행률은 "실행 순서"가 아니라 "가중치"로만 정해진다 — 각 항목은 자기 몫(위 `recomputePhotoProgress`/
    /// `recomputeAlbumProgress` 참고)만큼의 독립적인 0~1 값이고, 매번 가중합해서 다시 계산한다. 그래서
    /// 두 항목이 동시에 끝나면 둘 다 그대로 반영되고, 어느 순서로 끝나든 상관없다. 사진 분석 게이지와
    /// 앨범 생성 게이지도 서로 독립적으로 각자 진행된다.
    ///
    /// "사진 분석 완료"/"앨범 생성 완료" 신호는 주소+라벨 두 스트림이 다 끝나는 시점(아래 for-loop가
    /// 끝나는 시점)에 쏜다 — 위 두 트랙에서 파생되는 앨범 생성 작업들(여행/지역/카테고리/얼굴/동물/
    /// 중복탐지)은 전부 최선형(best-effort)이라, 이 시점에 아직 안 끝났어도 계속 진행되며
    /// autoAlbumProgressRatio를 갱신하고 플로팅 미니 진행률이 그걸 이어서 보여준다.
    private func analysis() async {
        guard !isAnalyzing else { return }
        self.isAnalyzing = true
        self.progressRatio = 0
        self.autoAlbumProgressRatio = 0
        self.isComplete = false
        self.resetProgressComponents()

        let startedAt = Date()
        debugLog("⏱️ [분석] 시작: \(startedAt)")

        // onXCompleted 콜백 안에서 뜨는 Task들은 "던져놓고 안 기다리는" fire-and-forget이라, 아래
        // for-loop만 끝나면(주소+라벨 "스트림" 자체가 끝난 시점) 이 셋이 실제로 다 끝났는지와 무관하게
        // 다음 코드로 넘어가 버렸다 — 그래서 라벨 트랙(카테고리→얼굴/동물→중복탐지)이 몇십 초씩 더
        // 돌고 있는데도 "완료" 신호가 먼저 나가서 시트가 중간에 뚝 닫히는 버그가 있었다(2단계 미니
        // 위젯으로도 안 넘어가고 그냥 사라짐). 이 세 Task를 붙잡아뒀다가 루프가 끝난 뒤 실제로 다
        // 끝날 때까지 기다린 다음에만 완료 신호를 쏘도록 고쳤다.
        var basicScanTask: Task<Void, Never>?
        var addressTrackTask: Task<Void, Never>?
        var labelTrackTask: Task<Void, Never>?

        do {
            for try await progress in analysisUseCase.analysis(
                onBasicScanCompleted: { [weak self] in
                    debugLog("⏱️ [분석] 기본 스캔 완료 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                    debugLog("⏱️ [분석] 지오코딩+라벨 스트림 시작 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                    basicScanTask = Task { @MainActor in
                        let stepStartedAt = Date()
                        debugLog("⏱️ [분석] 날짜 앨범 생성 시작 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                        try? await self?.autoAlbumUseCase.createDateAlbumsEarly()
                        if let self {
                            self.dateProgress = 1
                            self.recomputePhotoProgress()
                        }
                        debugLog("⏱️ [분석] 날짜 앨범 생성 완료 — 구간 \(String(format: "%.1f", Date().timeIntervalSince(stepStartedAt)))초, 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                    }
                },
                onAddressStreamCompleted: { [weak self] in
                    debugLog("⏱️ [분석] 주소(지오코딩) 스트림 완료 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                    addressTrackTask = Task { @MainActor in
                        if let self {
                            self.addressProgress = 1
                            self.recomputePhotoProgress()
                        }
                        let stepStartedAt = Date()
                        debugLog("⏱️ [분석] 여행+지역 앨범 생성 시작 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                        // createTravelAlbumsEarly 안에서 여행 앨범 만들고 바로 이어서 지역 분류까지
                        // 끝낸다(둘 다 주소만 있으면 되는 작업이라 라벨을 기다릴 필요가 없다).
                        try? await self?.autoAlbumUseCase.createTravelAlbumsEarly()
                        if let self {
                            self.travelProgress = 1
                            self.regionProgress = 1
                            self.recomputeAlbumProgress()
                        }
                        debugLog("⏱️ [분석] 여행+지역 앨범 생성 완료 — 구간 \(String(format: "%.1f", Date().timeIntervalSince(stepStartedAt)))초, 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                    }
                },
                onLabelStreamCompleted: { [weak self] in
                    debugLog("⏱️ [분석] 라벨+임베딩 스트림 완료 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                    labelTrackTask = Task { @MainActor in
                        let stepStartedAt = Date()

                        // 카테고리는 라벨만 있으면 되고 얼굴/동물·중복탐지 결과가 필요 없어서 먼저 끝낸다.
                        debugLog("⏱️ [분석] 카테고리 앨범 생성 시작 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                        try? await self?.autoAlbumUseCase.createCategoryAlbumsEarly()
                        if let self {
                            self.categoryProgress = 1
                            self.recomputeAlbumProgress()
                        }
                        debugLog("⏱️ [분석] 카테고리 앨범 생성 완료 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")

                        debugLog("⏱️ [분석] 얼굴/동물 앨범 생성 시작 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                        // createPersonAndSimilarAlbums의 onProgress는 얼굴(0~0.5)/동물(0.5~1.0) 순서로
                        // 하나의 0~1 값에 실어 보낸다 — 여기서 그 구간을 갈라 얼굴/동물을 따로 노출한다
                        // (자세히 체크리스트에서 둘을 별개 행으로 보여주기 위함).
                        try? await self?.autoAlbumUseCase.createPersonAndSimilarAlbums { ratio in
                            Task { @MainActor in
                                guard let self else { return }
                                if ratio <= 0.5 {
                                    self.faceProgress = max(self.faceProgress, ratio * 2)
                                } else {
                                    self.faceProgress = 1
                                    self.animalProgress = max(self.animalProgress, (ratio - 0.5) * 2)
                                }
                                self.recomputeAlbumProgress()
                            }
                        }
                        // createPersonAndSimilarAlbums 안에서 여행자 연결까지 같이 끝난 뒤 리턴된다
                        if let self {
                            self.faceProgress = 1
                            self.animalProgress = 1
                            self.travelerLinkProgress = 1
                            self.recomputeAlbumProgress()
                        }
                        debugLog("⏱️ [분석] 얼굴/동물 앨범 생성 + 여행자 연결 완료 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")

                        // 중복(비슷한) 사진 탐지 — 전체 임베딩 추출+비교가 대부분의 시간을 차지해서
                        // 분석 게이지의 몫으로 노출한다. 앨범 저장도 이 호출 안에서 같이 끝나므로,
                        // 끝나자마자 앨범생성 게이지의 "중복앨범저장" 몫도 같이 올린다.
                        debugLog("⏱️ [분석] 중복 사진 탐지 시작 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                        try? await self?.autoAlbumUseCase.detectDuplicatePhotos { ratio in
                            Task { @MainActor in
                                guard let self else { return }
                                self.dupDetectProgress = max(self.dupDetectProgress, ratio)
                                self.recomputePhotoProgress()
                            }
                        }
                        if let self {
                            self.dupDetectProgress = 1
                            self.dupSaveProgress = 1
                            self.recomputePhotoProgress()
                            self.recomputeAlbumProgress()
                        }
                        debugLog("⏱️ [분석] 라벨 트랙(카테고리/얼굴/동물/중복탐지) 전체 완료 — 구간 \(String(format: "%.1f", Date().timeIntervalSince(stepStartedAt)))초, 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")
                    }
                }
            ) {
                switch progress.state {
                case .progress(let ratio):
                    self.streamProgress = max(self.streamProgress, ratio)
                    self.recomputePhotoProgress()
                case .completed:
                    self.streamProgress = 1
                    self.recomputePhotoProgress()
                case .unavailable:
                    break
                }
            }
            self.streamProgress = 1
            self.recomputePhotoProgress()
            debugLog("⏱️ [분석] 주소+라벨 스트림 전체 완료 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")

            // "스트림"(주소+라벨 입력) 자체는 끝났어도, 거기서 파생된 앨범 생성 작업(날짜/여행/지역/
            // 카테고리/얼굴/동물/중복탐지)은 위 onXCompleted 콜백들이 fire-and-forget으로 띄운 Task라
            // 아직 안 끝났을 수 있다 — 특히 라벨 트랙(카테고리→얼굴/동물→중복탐지)은 몇십 초씩 걸린다.
            // 이걸 기다리지 않고 완료 신호를 쏘면 시트/미니위젯/배지가 실제로는 안 끝났는데 먼저
            // 닫혀버린다. 셋 다 실제로 끝날 때까지 여기서 기다린다.
            await basicScanTask?.value
            await addressTrackTask?.value
            await labelTrackTask?.value
            debugLog("⏱️ [분석] 파생 앨범 생성 작업(날짜/여행/지역/카테고리/얼굴/동물/중복) 전체 완료 — 누적 \(String(format: "%.1f", Date().timeIntervalSince(startedAt)))초")

            self.photoCompletedSubject.send(())
            try? await legacyAccessUseCase.markLegacyFreeAccess()

            self.progressRatio = 1.0
            self.autoAlbumProgressRatio = 1.0
            self.isComplete = true
            self.albumCompletedSubject.send(())
            self.endAllProcess()
        } catch {
            self.progressRatio = 1.0
            self.autoAlbumProgressRatio = 1.0
            self.isComplete = true
            self.photoCompletedSubject.send(())
            self.albumCompletedSubject.send(())
        }
        self.isAnalyzing = false

        let finishedAt = Date()
        let elapsedMinutes = finishedAt.timeIntervalSince(startedAt) / 60
        debugLog("⏱️ [분석] 종료: \(finishedAt) — 총 \(String(format: "%.1f", elapsedMinutes))분 소요")
    }

    private func runAlbumGeneration(fullRegenerate: Bool = false) async {
        self.isComplete = false
        do {
            for try await progress in autoAlbumUseCase.generateAllAlbums(fullRegenerate: fullRegenerate) {
                self.autoAlbumProgressRatio = progress.ratio
                if case .completed = progress.step {
                    self.autoAlbumProgressRatio = 1.0
                    self.isComplete = true
                    self.albumCompletedSubject.send(())
                    self.endAllProcess()
                }
            }
        } catch {
            self.autoAlbumProgressRatio = 1.0
            self.isComplete = true
            self.albumCompletedSubject.send(())
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
