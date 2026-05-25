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
    let folderProgress: AnyPublisher<Double, Never>
    let locationProgress: AnyPublisher<Double, Never>
    let locationFolderProgress: AnyPublisher<Double, Never>
}

@MainActor
public final class TabbarViewModel: BaseViewModel {
    
    enum Input {
        case analysis
        case autoTravelFolder
        case reAutoFolder
        case reanalysis
        case clear
        case permission
        case showConsent
        case afterConsent
        case showOnboarding
        case afterOnboarding
    }
    
    public struct Output {
        let photoProgress: AnyPublisher<Double, Never>
        let folderProgress: AnyPublisher<Double, Never>
        let locationProgress: AnyPublisher<Double, Never>
        let locationFolderProgress: AnyPublisher<Double, Never>
        let onboarding: AnyPublisher<Bool?, Never>
        let consent: AnyPublisher<Bool?, Never>
        let permission: AnyPublisher<PhotoPermission, Never>
        let isCleared: AnyPublisher<Bool, Never>
    }
    
    @Published private var progressRatio: Double = 0
    @Published private var autoFolderProgressRatio: Double = 0
    @Published private var locationProgressRatio: Double = 0
    @Published private var locationFolderProgressRatio: Double = 0
    @Published private var isAnalyzing : Bool = false
    @Published private var isCleared: Bool = false
    @Published private var onboarding: Bool?
    @Published private var consent: Bool?
    @Published private var permission: PhotoPermission = .notDetermined
    
    var onAction: ((TabbarViewModelAction) -> Void)?
    
    let input = PassthroughSubject<Input, Never>()
    
    private let permissionUseCase: PermissionUseCase
    private let analysisUseCase: PhotoAnalysisUseCase
    private let autoFolderUseCase: AutoFolderUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    init(permissionUseCase: PermissionUseCase,
         analysisUseCase: PhotoAnalysisUseCase,
         autoFolderUseCase: AutoFolderUseCase) {
        self.permissionUseCase = permissionUseCase
        self.analysisUseCase = analysisUseCase
        self.autoFolderUseCase = autoFolderUseCase
        
        super.init()
        
        self.bind()
        
//        self.resetForTest()
    }
    
    public func transform() -> Output {
        return Output(
            photoProgress: $progressRatio.eraseToAnyPublisher(),
            folderProgress: $autoFolderProgressRatio.eraseToAnyPublisher(),
            locationProgress: $locationProgressRatio.eraseToAnyPublisher(),
            locationFolderProgress: $locationFolderProgressRatio.eraseToAnyPublisher(),
            onboarding: $onboarding.eraseToAnyPublisher(),
            consent: $consent.eraseToAnyPublisher(),
            permission: $permission.eraseToAnyPublisher(),
            isCleared: $isCleared.eraseToAnyPublisher()
        )
    }
    
    func send(_ input: Input) {
        print("send", input)
        self.input.send(input)
    }
    
    private func bind() {
        self.input.sink { [weak self] input in
            guard let self else { return }
            Task { @MainActor in await self.handle(input) }
        }
        .store(in: &cancellables)
    }
    
    private func resetForTest() {
        Task {
            do {
                print("reset")
                try await self.permissionUseCase.resetForTest()
            }
        }
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
            print("analysis 2")
            showAlert(
                title: "사진 분석",
                message: "분석하지 않은 사진을 분석합니다.\n분석할까요?",
                buttons: [
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil),
                    AlertButtonConfig(title: "분석하기", style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            self.onAction?(.progressSheet(AnalyzeProgress(
                                photoProgress: self.$progressRatio.eraseToAnyPublisher(),
                                folderProgress: self.$autoFolderProgressRatio.eraseToAnyPublisher(),
                                locationProgress: self.$locationProgressRatio.eraseToAnyPublisher(),
                                locationFolderProgress: self.$locationFolderProgressRatio.eraseToAnyPublisher()
                            )))
//                            self.isLoading = true
                            print("start date!!!:", Date())
                            await self.analysis()
//                            self.isLoading = false
                            print("end date!!!:", Date())
                        }
                    }
                ]
            )
        case .autoTravelFolder:
            print("autoTravelFolder")
            showAlert(
                title: "여행 사진",
                message: "여행 앨범을 만들어 볼까요",
                buttons: [
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil),
                    AlertButtonConfig(title: "만들어줘", style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
//                            self.isLoading = true
                            print("start date!!!:", Date())
                            await self.createTravelAutoFolder()
//                            self.isLoading = false
                            print("end date!!!:", Date())
                        }
                    }
                ]
            )
        case .reAutoFolder:
            showAlert(
                title: "자동 폴더 재생성",
                message: "자동 생서된 앨범들을\n삭제 후 다시 생성합니다.\n다시 생성할까요?",
                buttons: [
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil),
                    AlertButtonConfig(title: "재분석하기", style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            self.isLoading = true
                            await self.folderClear()
                            self.isLoading = false
                            
                            self.onAction?(.progressSheet(AnalyzeProgress(
                                photoProgress: self.$progressRatio.eraseToAnyPublisher(),
                                folderProgress: self.$autoFolderProgressRatio.eraseToAnyPublisher(),
                                locationProgress: self.$locationProgressRatio.eraseToAnyPublisher(),
                                locationFolderProgress: self.$locationFolderProgressRatio.eraseToAnyPublisher()
                            )))
                            
                            self.progressRatio = 1.0
                            
                            _ = await self.createdAutoFolder(isPhoto: true) {
                                self.autoFolderProgressRatio = $0
                            }
                        }
                    }
                ]
            )
        case .reanalysis:
            showAlert(
                title: "처음부터 분석하기",
                message: "저장된 사진 및 앨범을\n삭제 후 다시 분석합니다.\n다시 분석할까요?",
                buttons: [
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil),
                    AlertButtonConfig(title: "재분석하기", style: .default) { [weak self] in
                        Task {
                            guard let self else {return}
                            self.isLoading = true
                            await self.clear()
                            self.isLoading = false
                            
                            self.onAction?(.progressSheet(AnalyzeProgress(
                                photoProgress: self.$progressRatio.eraseToAnyPublisher(),
                                folderProgress: self.$autoFolderProgressRatio.eraseToAnyPublisher(),
                                locationProgress: self.$locationProgressRatio.eraseToAnyPublisher(),
                                locationFolderProgress: self.$locationFolderProgressRatio.eraseToAnyPublisher()
                            )))
                            await self.analysis()
                        }
                    }
                ]
            )
        case .clear:
            showAlert(
                title: "초기화",
                message: "저장된 사진 및 앨범을 모두 삭제하시겠습니까?",
                buttons: [
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil),
                    AlertButtonConfig(title: "삭제", style: .destructive) { [weak self] in
                        Task {
                            self?.isLoading = true
                            await self?.clear()
                            self?.isLoading = false
                        }
                    }
                ]
            )
        case .permission:
            await checkPermission()
        }
    }
    
    private func analysis() async {
        self.isAnalyzing = true
        do {
            let success = try await analysisPhotoBase()
            guard success else {
                self.isAnalyzing = false
                return
            }
            
            await locationAnalysis()
        } catch {
            print("error", error.localizedDescription)
            self.progressRatio = 1.0
            self.isAnalyzing = false
        }
    }
    
    private func locationAnalysis() async {
        self.isAnalyzing = true
        Task.detached(priority: .background) { [weak self] in
            guard let self else {return}
            await self.analysisPhotoLocation()
            await MainActor.run {
                self.isAnalyzing = false
            }
        }
    }
    
    private func createTravelAutoFolder() async {
        do {
            self.isLoading = true
            
            for try await progress in autoFolderUseCase.createTravelAutoFolder() {
                await MainActor.run {
                    if case .completed = progress.step {
                        self.isLoading = false
                    }
                }
            }
        } catch {
            self.isLoading = false
        }
    }
    
    private func clear() async {
        do {
            self.isCleared = false
            try await self.autoFolderUseCase.deletePhotos()
            self.isCleared = true
        } catch {
            print("error", error.localizedDescription)
        }
    }
    
    private func folderClear() async {
        do {
            self.isCleared = false
            print("delete all folder")
            try await self.autoFolderUseCase.deleteAutoFolders()
            print("deleted all folder")
            self.isCleared = true
        } catch {
            print("error", error.localizedDescription)
        }
    }
    
    private func createdAutoFolder(isPhoto: Bool, updateProgress: @MainActor (Double) -> Void) async -> Bool {
        do {
            for try await progress in autoFolderUseCase.execute(isPhoto) {
                await MainActor.run {
                    updateProgress(progress.ratio)
                    if case .completed = progress.step {
                        updateProgress(1.0)
                    }
                }
            }
            return true
        } catch {
            return false
        }
    }
    
    private func analysisPhotoBase() async throws -> Bool {
        
        for try await progress in analysisUseCase.analysis() {
            switch progress.state {
            case .progress(let ratio):
                print("progress", ratio)
                self.progressRatio = ratio
            case .completed:
                print("completed")
                self.progressRatio = 1.0
            case .unavailable(let reason):
//                self.showUnavailableMessage(reason)
                print("reason", reason)
            }
        }
        self.progressRatio = 1.0
        
        return await createdAutoFolder(isPhoto: true) {
            self.autoFolderProgressRatio = $0
        }
        
    }
    
    private func analysisPhotoLocation() async {
        do {
            for try await progress in self.analysisUseCase.locationAnalysis() {
                await MainActor.run {
                    switch progress.state {
                    case .progress(let ratio):
                        print("progress", ratio)
                        self.locationProgressRatio = ratio
                    case .completed:
                        print("completed")
                        self.locationProgressRatio = 1.0
                    case .unavailable(let reason):
//                        self.showUnavailableMessage(reason)
                        print("reason", reason)
                    }
                }
            }
        } catch {
            print("error", error.localizedDescription)
            self.locationProgressRatio = 1.0
        }
        
        _ = await self.createdAutoFolder(isPhoto: false) {
            self.locationFolderProgressRatio = $0
        }
    }
    
    private func checkConsent() async {
        do {
            self.consent = try await permissionUseCase.showConsent()
        } catch {
            print("checkConsent failed")
        }
    }
    
    private func consentComplete() async {
        do {
            try await permissionUseCase.completeConsent()
        } catch {
            print("consentComplete fail")
        }
    }
    
    private func checkOnboarding() async {
        do {
            self.onboarding = try await permissionUseCase.showOnboarding()
        } catch {
            print("checkConsent failed")
        }
    }
    
    private func onboardingComplete() async {
        do {
            try await permissionUseCase.completeOnboarding()
        } catch {
            print("consentComplete fail")
        }
    }
    
    private func checkPermission() async {
        do {
            self.permission = try await permissionUseCase.checkPermission()
        } catch {
            print("checkPermission failed")
        }
    }
}
