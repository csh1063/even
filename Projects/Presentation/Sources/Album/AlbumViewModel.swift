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

@MainActor
public final class AlbumViewModel {
    
    enum Input {
        case analysis
    }
    
    public struct Output {
        let progressRatio: AnyPublisher<Double, Never>
    }
    
    @Published var progressRatio: Double = 0
    @Published var autoFolderProgressRatio: Double = 0
    @Published var locationProgressRatio: Double = 0
    @Published var isAnalyzing : Bool = false
    
    let input = PassthroughSubject<Input, Never>()
    
    private let analysisUseCase: PhotoAnalysisUseCase
    private let autoFolderUseCase: AutoFolderUseCase
    private var cancellable = Set<AnyCancellable>()
    
    public init(analysisUseCase: PhotoAnalysisUseCase,
                autoFolderUseCase: AutoFolderUseCase) {
        
        self.analysisUseCase = analysisUseCase
        self.autoFolderUseCase = autoFolderUseCase
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
            self.isAnalyzing = true
            do {

                for try await progress in analysisUseCase.analysis() {
                    switch progress.state {
                    case .progress(let ratio):
                        print("progress", ratio)
                        self.progressRatio = ratio
                    case .completed:
                        print("completed")
                        self.progressRatio = 1.0
                    case .unavailable(let reason):
//                        self.showUnavailableMessage(reason)
                        print("reason", reason)
                    }
                }
                
                for try await progress in autoFolderUseCase.execute() {
                    self.autoFolderProgressRatio = progress.ratio
                    switch progress.step {
                    case .analyzing: break
//                        self.statusMessage = "라벨 분석 중..."
                    case .creatingFolders: break
//                        self.statusMessage = "폴더 생성 중..."
                    case .classifying: break
//                        self.statusMessage = "사진 분류 중..."
                    case .completed:
                        self.autoFolderProgressRatio = 1.0
//                        self.statusMessage = "완료!"
                    }
                }
                
                // 2차 - 위치 분석 (백그라운드)
                Task.detached(priority: .background) {
                    for try await progress in await self.analysisUseCase.locationAnalysis() {
                        await MainActor.run {
                            switch progress.state {
                            case .progress(let ratio):
                                print("progress", ratio)
                                self.locationProgressRatio = ratio
                            case .completed:
                                print("completed")
                                self.locationProgressRatio = 1.0
                                self.isAnalyzing = false
                            case .unavailable(let reason):
        //                        self.showUnavailableMessage(reason)
                                print("reason", reason)
                                self.isAnalyzing = false
                            }
                        }
                    }
                }
            }
            catch {
                print("error", error.localizedDescription)
                self.isAnalyzing = false
            }
        }
    }
}
