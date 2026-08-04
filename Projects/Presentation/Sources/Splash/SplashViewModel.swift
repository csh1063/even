//
//  SplashViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine
import Domain

@MainActor
public final class SplashViewModel: BaseViewModel {

    enum Input {
        case appear
        case endAnim
    }

    struct Output {
        let finished: AnyPublisher<Bool, Never>
    }

    private let input = PassthroughSubject<Input, Never>()

    @Published private var finished: Bool = false
    private let appearSubject = PassthroughSubject<Void, Never>()
    private let animDoneSubject = PassthroughSubject<Void, Never>()

    private let useCase: PhotoCheckUseCase
    private let versionCheckUseCase: AppVersionCheckUseCase

    private var cancellables = Set<AnyCancellable>()

    public init(useCase: PhotoCheckUseCase, versionCheckUseCase: AppVersionCheckUseCase) {
        self.useCase = useCase
        self.versionCheckUseCase = versionCheckUseCase

        super.init()

        self.bind()
    }

    func transform() -> Output {
        Output(finished: $finished.eraseToAnyPublisher())
    }

    func send(_ input: Input) {
        self.input.send(input)
    }

    private func bind() {
        input.sink { [weak self] input in
            guard let self else { return }
            Task { @MainActor in await self.handle(input) }
        }
        .store(in: &cancellables)

        appearSubject.zip(animDoneSubject)
            .first()
            .sink { [weak self] _ in
                Task {
//                if endAppear && endAnim {
                    await self?.start()
//                }
                }
            }
            .store(in: &cancellables)
    }

    private func handle(_ input: Input) async {
        switch input {
        case .appear:
            await self.checkVersion()
        case .endAnim:
            self.animDoneSubject.send()
        }
    }

    private func checkVersion() async {
        switch await versionCheckUseCase.check() {
        case .forceUpdate:
            showForceUpdateAlert()
        case .recommendUpdate:
            showRecommendUpdateAlert()
        case .upToDate:
            await self.checkDeletedPhoto()
        }
    }

    private func showForceUpdateAlert() {
        showAlert(
            title: String(localized: "업데이트 필요", bundle: .module),
            message: String(localized: "새로운 버전으로 업데이트해야 계속 이용할 수 있어요.", bundle: .module),
            buttons: [
                AlertButtonConfig(title: String(localized: "종료", bundle: .module), style: .destructive) {
                    exit(0)
                },
                AlertButtonConfig(title: String(localized: "업데이트", bundle: .module), style: .default) {
                    self.openAppStore()
                }
            ]
        )
    }

    private func showRecommendUpdateAlert() {
        showAlert(
            title: String(localized: "업데이트 안내", bundle: .module),
            message: String(localized: "새로운 버전이 있어요. 업데이트하시겠어요?", bundle: .module),
            buttons: [
                AlertButtonConfig(title: String(localized: "나중에", bundle: .module), style: .cancel) {
                    Task {
                        await self.checkDeletedPhoto()
                    }
                },
                AlertButtonConfig(title: String(localized: "업데이트", bundle: .module), style: .default) {
                    self.openAppStore()
                }
            ]
        )
    }

    private func openAppStore() {
        guard let url = URL(string: AppStoreInfo.urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func checkDeletedPhoto() async {
        do {
            for try await progress in try await self.useCase.checkDeletedPhoto() {
                switch progress {
                case .progress(let ratio):
                    debugLog("check progress: \(ratio)")
                case .completed:
                    await self.syncData()
                case .unavailable(let reason):
                    debugLog("check reason: \(reason)")
                }
            }

        } catch {
            debugLog("error: \(error.localizedDescription)")
        }
    }

    private func syncData() async {
        do {
            for try await progress in try await self.useCase.syncCoverAndCount() {
                switch progress {
                case .progress(let ratio):
                    debugLog("syncData progress: \(ratio)")
                case .completed:
//                    await self.start()
                    appearSubject.send()
                case .unavailable(let reason):
                    debugLog("syncData reason: \(reason)")
                }
            }
        } catch {
            debugLog("error: \(error.localizedDescription)")
        }
    }

    private func start() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 3초 (1초 = 1_000_000_000 ns)
        self.finished = true
    }
}
