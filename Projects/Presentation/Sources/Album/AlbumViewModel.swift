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
import UIKit

@MainActor
public final class AlbumViewModel {
    
    enum Input {
        case appear
        case analysis
        case clear
        case dummy
        case selectItem(Folder)
    }
    
    public struct Output {
        let folders: AnyPublisher<[Folder], Never>
        let progressRatio: AnyPublisher<Double, Never>
        let autoFolderProgressRatio: AnyPublisher<Double, Never>
        let locationProgressRatio: AnyPublisher<Double, Never>
        let locationFolderProgressRatio: AnyPublisher<Double, Never>
        let isAnalyzing: AnyPublisher<Bool, Never>
    }
    
    @Published private var folders: [Folder] = []
    @Published private var progressRatio: Double = 0
    @Published private var autoFolderProgressRatio: Double = 0
    @Published private var locationProgressRatio: Double = 0
    @Published private var locationFolderProgressRatio: Double = 0
    @Published private var isAnalyzing : Bool = false
    
    let input = PassthroughSubject<Input, Never>()
    
    private weak var coordinator: AlbumCoordinator?
    private let photoUseCase: PhotoLibraryUseCase
    private let analysisUseCase: PhotoAnalysisUseCase
    private let autoFolderUseCase: AutoFolderUseCase
    private let folderUseCase: FolderUseCase
    
    private var cancellable = Set<AnyCancellable>()
    
    public init(coordinator: AlbumCoordinator,
                photoUseCase: PhotoLibraryUseCase,
                analysisUseCase: PhotoAnalysisUseCase,
                autoFolderUseCase: AutoFolderUseCase,
                folderUseCase: FolderUseCase) {
        
        self.coordinator = coordinator
        self.photoUseCase = photoUseCase
        self.analysisUseCase = analysisUseCase
        self.autoFolderUseCase = autoFolderUseCase
        self.folderUseCase = folderUseCase
        self.bind()
    }
    
    public func transform() -> Output {
        return Output(
            folders: $folders.eraseToAnyPublisher(),
            progressRatio: $progressRatio.eraseToAnyPublisher(),
            autoFolderProgressRatio: $autoFolderProgressRatio.eraseToAnyPublisher(),
            locationProgressRatio: $locationProgressRatio.eraseToAnyPublisher(),
            locationFolderProgressRatio: $locationFolderProgressRatio.eraseToAnyPublisher(),
            isAnalyzing: $isAnalyzing.eraseToAnyPublisher()
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
        case .appear:
            _ = await self.loadFodlers()
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
                
                let success = await self.loadFodlers()
                guard success else {
                    self.isAnalyzing = false
                    return
                }
                
//                 2차 - 위치 분석 (백그라운드)
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
//                                self.isAnalyzing = false
                            case .unavailable(let reason):
        //                        self.showUnavailableMessage(reason)
                                print("reason", reason)
//                                self.isAnalyzing = false
                            }
                        }
                    }
                    
                    for try await progress in await self.autoFolderUseCase.execute() {
                        await MainActor.run {
                            self.locationFolderProgressRatio = progress.ratio
                            switch progress.step {
                            case .analyzing: break
//                                self.statusMessage = "라벨 분석 중..."
                            case .creatingFolders: break
//                                self.statusMessage = "폴더 생성 중..."
                            case .classifying: break
//                                self.statusMessage = "사진 분류 중..."
                            case .completed:
                                self.locationFolderProgressRatio = 1.0
//                                self.statusMessage = "완료!"
                            }
                        }
                    }
                    _ = await self.loadFodlers()
                    await MainActor.run {
                        self.isAnalyzing = false
                    }
                }
            }
            catch {
                print("error", error.localizedDescription)
                self.isAnalyzing = false
            }
        case .clear:
            do {
                try await self.analysisUseCase.deletePhotos()
                _ = await self.loadFodlers()
            }
            catch {
                print("error", error.localizedDescription)
            }
        case .dummy:
            do {
                print("create dummy!")
                try await self.folderUseCase.createDummy()
                _ = await self.loadFodlers()
            }
            catch {
                
            }
        case .selectItem(let folder):
            print("!!!")
            if self.coordinator == nil {
                    print("🚨 에러: Coordinator가 nil입니다!")
                }
            self.coordinator?.moveDetail(folder: folder)
        }
    }
    
    private func loadFodlers() async -> Bool {
        do {
            print("load folders")
            let folders = try await self.folderUseCase.fetchAll()
            self.folders = folders
            return true
        }
        catch {
            print("loadFodlers error")
            return false
        }
    }
    
    func loadImage(id: String, size: CGSize) async -> UIImage? {
        do {
            guard let cgImage: CGImage = try await photoUseCase.loadImage(
                id: id,
                type: .specialSize(size)
            ).cgImage else {
                return nil
            }
            
            return UIImage(cgImage: cgImage)
        } catch {
            print("이미지 로딩 실패: \(error.localizedDescription)")
            return nil
        }
    }
}

extension AlbumViewModel: ImageLoadable {
}
