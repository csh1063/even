//
//  AlbumViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine
import Domain

public final class AlbumViewModel {
    
    enum Input {
        case analysis
    }
    
    public struct Output {
        let progressRatio: AnyPublisher<Double, Never>
    }
    
    @Published var progressRatio: Double = 0
    @Published var isAnalyzing : Bool = false
    
    let input = PassthroughSubject<Input, Never>()
    
    private let analysisUsecase: PhotoAnalysisUsecase
    private var cancellable = Set<AnyCancellable>()
    
    public init(analysisUsecase: PhotoAnalysisUsecase) {
        
        self.analysisUsecase = analysisUsecase
        self.bind()
    }
    
    public func transform() -> Output {
        return Output(
            progressRatio: $progressRatio.eraseToAnyPublisher()
        )
    }
    
    func send(_ input: Input) {
        print("send", input)
        self.input.send(input)
    }
    
    private func bind() {
        self.input.sink { [weak self] input in
            guard let self else { return }
            Task { await self.handle(input) }
        }
        .store(in: &cancellable)
    }
    
    private func handle(_ input: Input) async {
        
        switch input {
        case .analysis:
            do {
                // analysis가 async throws 이기 때문에 try await 이 각각
                for try await progress in try await analysisUsecase.analysis() {
                    switch progress.state {
                    case .progress(let ratio):
                        self.progressRatio = ratio
                    case .completed:
                        self.isAnalyzing = false
                    case .unavailable(let reason):
//                        self.showUnavailableMessage(reason)
                        print("reason", reason)
                    }
                }
            }
            catch {
                print("error", error.localizedDescription)
            }
        }
    }
}
