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
        case selectItem(Folder)
    }
    
    public struct Output {
        let folders: AnyPublisher<[Folder], Never>
        let isLoading: AnyPublisher<Bool, Never>
    }
    
    @Published private var folders: [Folder] = []
    
    var onAction: ((AlbumViewModelAction) -> Void)?
    
    let input = PassthroughSubject<Input, Never>()
    
    private let tabbarViewModel: TabbarViewModel
    private let imageUseCase: PhotoImageUseCase
    private let folderUseCase: FolderUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(tabbarViewModel: TabbarViewModel,
                imageUseCase: PhotoImageUseCase,
                folderUseCase: FolderUseCase) {
        
        self.tabbarViewModel = tabbarViewModel
        self.imageUseCase = imageUseCase
        self.folderUseCase = folderUseCase
        
        super.init()
        
        self.bind()
        
        folderUseCase.foldersPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$folders)
    }
    
    public func transform() -> Output {
        return Output(
            folders: $folders.eraseToAnyPublisher(),
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
            print("analysis 1")
            tabbarViewModel.send(.analysis)
        case .clear:
            tabbarViewModel.send(.clear)
        case .selectItem(let folder):
            print("!!!")
            self.onAction?(.moveDetail(folder: folder))
        }
    }
    
    private func loadFodlers() async {
        do {
            print("load folders")
            let folders = try await self.folderUseCase.fetchAll()
            self.folders = folders
        } catch {
            print("loadFodlers error")
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
