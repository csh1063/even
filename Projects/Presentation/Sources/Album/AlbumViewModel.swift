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

enum AlbumViewModelAction {
    case moveDetail(folder: Folder)
}

@MainActor
public final class AlbumViewModel: BaseViewModel {
    
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
        let isLoading: AnyPublisher<Bool, Never>
    }
    
    @Published private var folders: [Folder] = []
    @Published private var progressRatio: Double = 0
    @Published private var autoFolderProgressRatio: Double = 0
    @Published private var locationProgressRatio: Double = 0
    @Published private var locationFolderProgressRatio: Double = 0
    @Published private var isAnalyzing : Bool = false
    
    var onAction: ((AlbumViewModelAction) -> Void)?
    
    let input = PassthroughSubject<Input, Never>()
    
    private let imageUseCase: PhotoImageUseCase
    private let analysisUseCase: PhotoAnalysisUseCase
    private let autoFolderUseCase: AutoFolderUseCase
    private let folderUseCase: FolderUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(imageUseCase: PhotoImageUseCase,
                analysisUseCase: PhotoAnalysisUseCase,
                autoFolderUseCase: AutoFolderUseCase,
                folderUseCase: FolderUseCase) {
        
        self.imageUseCase = imageUseCase
        self.analysisUseCase = analysisUseCase
        self.autoFolderUseCase = autoFolderUseCase
        self.folderUseCase = folderUseCase
        
        super.init()
        
        self.bind()
        
//        folderUseCase.foldersPublisher
//            .receive(on: DispatchQueue.main)
//            .assign(to: &$folders)
    }
    
    public func transform() -> Output {
        return Output(
            folders: $folders.eraseToAnyPublisher(),
            progressRatio: $progressRatio.eraseToAnyPublisher(),
            autoFolderProgressRatio: $autoFolderProgressRatio.eraseToAnyPublisher(),
            locationProgressRatio: $locationProgressRatio.eraseToAnyPublisher(),
            locationFolderProgressRatio: $locationFolderProgressRatio.eraseToAnyPublisher(),
            isAnalyzing: $isAnalyzing.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher()
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
        .store(in: &cancellables)
    }
    
    private func handle(_ input: Input) async {
        switch input {
        case .appear:
            self.isLoading = true
            _ = await self.loadFodlers()
            self.isLoading = false
        case .analysis:
            showAlert(
                title: "사진 분석",
                message: (self.folders.count == 0 ? "사진첩의 모든 사진을 분석합니다.":"추가된 사진을 분석합니다."),
                buttons: [
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil),
//                    AlertButtonConfig(title: "이어서 위치 분석", style: .default) { [weak self] in
//                        Task {
//                            self?.isLoading = true
//                            await self?.locationAnalysis(isFull: false)
//                            self?.isLoading = false
//                        }
//                    },
                    AlertButtonConfig(title: "분석하기", style: .default) { [weak self] in
                        Task {
                            self?.isLoading = true
                            await self?.analysis(isFull: false)
                            self?.isLoading = false
                        }
                    }
//                    , AlertButtonConfig(title: "전체 분석", style: .default) { [weak self] in
//                        Task {
//                            self?.isLoading = true
//                            await self?.analysis(isFull: true)
//                            self?.isLoading = false
//                        }
//                    }
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
        case .dummy:
            do {
                print("create dummy!")
//                try await self.folderUseCase.createDummy()
                try await self.autoFolderUseCase.syncPhotoCount()
                _ = await self.loadFodlers()
            } catch {
                
            }
        case .selectItem(let folder):
            print("!!!")
            self.onAction?(.moveDetail(folder: folder))
        }
    }
    
    private func analysis(isFull: Bool) async {
        self.isAnalyzing = true
        do {
            let success = try await analysisPhotoBase(isFull: isFull)
            guard success else {
                self.isAnalyzing = false
                return
            }
            
            await locationAnalysis(isFull: isFull)
            // 2차 - 위치 분석 (백그라운드)
//            Task.detached(priority: .background) { [weak self] in
//                guard let self else {return}
//                try await self.analysisPhotoLocation(isFull: isFull)
//                await MainActor.run {
//                    self.isAnalyzing = false
//                }
//            }
        } catch {
            print("error", error.localizedDescription)
            self.isAnalyzing = false
        }
    }
    
    private func locationAnalysis(isFull: Bool) async {
        self.isAnalyzing = true
        Task.detached(priority: .background) { [weak self] in
            guard let self else {return}
            try await self.analysisPhotoLocation()
            await MainActor.run {
                self.isAnalyzing = false
            }
        }
    }
    
    private func clear() async {
        do {
            try await self.analysisUseCase.deletePhotos()
            _ = await self.loadFodlers()
        } catch {
            print("error", error.localizedDescription)
        }
    }
    
    private func analysisAndLoad(updateProgress: @MainActor (Double) -> Void) async throws -> Bool {
        for try await progress in autoFolderUseCase.execute() {
            await MainActor.run {
                updateProgress(progress.ratio)
                if case .completed = progress.step {
                    updateProgress(1.0)
                }
            }
        }
        return await loadFodlers()
    }
    
    private func analysisPhotoBase(isFull: Bool) async throws -> Bool {
        
        for try await progress in analysisUseCase.analysis(isFull: isFull) {
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
        self.progressRatio = 1.0
        
        return try await analysisAndLoad {
            self.autoFolderProgressRatio = $0
        }
        
    }
    
    private func analysisPhotoLocation() async throws {
        
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
        self.locationProgressRatio = 1.0
        
        _ = try await self.analysisAndLoad {
            self.locationFolderProgressRatio = $0
        }
    }
    
    private func loadFodlers() async -> Bool {
        do {
            print("load folders")
            let folders = try await self.folderUseCase.fetchAll()
            self.folders = folders
            return true
        } catch {
            print("loadFodlers error")
            return false
        }
    }
    
    func loadImage(id: String, size: CGSize) async -> UIImage? {
        do {
            guard let cgImage: CGImage = try await imageUseCase.loadImage(
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
