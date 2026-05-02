//
//  SplashViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine
import Domain

@MainActor
public final class SplashViewModel: BaseViewModel {
    
    enum Input {
        case appear
    }
    
    struct Output {
        let finished: AnyPublisher<Bool, Never>
    }
    
    
    private let input = PassthroughSubject<Input, Never>()
    @Published private var finished: Bool = false
    
    private let useCase: PhotoCheckUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(useCase: PhotoCheckUseCase) {
        self.useCase = useCase
        
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
    }
    
    private func handle(_ input: Input) async {
        switch input {
        case .appear:
            await self.checkDeletedPhoto()
        }
    }
    
    private func checkDeletedPhoto() async {
        do {
            print("checkDeletedPhoto")
            for try await progress in try await self.useCase.checkDeletedPhoto() {
                switch progress {
                case .progress(let ratio):
                    print("check progress:", ratio)
                case .completed:
                    print("check completed")
                    await self.syncData()
                case .unavailable(let reason):
                    print("check reason:", reason)
                }
            }
            
        } catch {
            print("error:",error.localizedDescription)
        }
    }
    
    private func syncData() async {
        do {
            print("syncData")
            for try await progress in try await self.useCase.syncCoverAndCount() {
                switch progress {
                case .progress(let ratio):
                    print("syncData progress:", ratio)
                case .completed:
                    print("syncData completed")
                    await self.start()
                case .unavailable(let reason):
                    print("syncData reason:", reason)
                }
            }
        } catch {
            print("error:",error.localizedDescription)
        }
    }

    private func start() async {
        print("start")
//        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3초 (1초 = 1_000_000_000 ns)
//            showAlert(
//                title: "진행?",
//                message: "진행 고고?",
//                buttons: [
//                    AlertButtonConfig(title: "껃영", style: .destructive, action: nil),
//                    AlertButtonConfig(title: "고고", style: .default) { [weak self] in
                        self.finished = true
//                    }
//                ]
//            )
//        }
    }
}
