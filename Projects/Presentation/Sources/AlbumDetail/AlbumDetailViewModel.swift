//
//  AlbumDetailViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Combine
import Domain
import UIKit

enum AlbumDetailViewModelAction {
    case options(folder: Folder)
    case pop
}

@MainActor
protocol AlbumDetailViewModelDelegate: AnyObject {
    func save(name: String)
    func deleteAlert()
}

@MainActor
public final class AlbumDetailViewModel: BaseViewModel {
    
    enum Input {
        case appear
        case refresh
        case more
        case dismiss
    }
    
    public struct Output {
        let name: AnyPublisher<String, Never>
        let photos: AnyPublisher<[Photo], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let errorMessage: AnyPublisher<String?, Never>
    }
 
    // 내부 상태값
//    @Published private var photoList: PhotoList?
    @Published private var folder: Folder
    @Published private var folderName: String
    @Published private var photos: [Photo] = []
    @Published private var hasNext: Bool = false
    @Published private var errorMessage: String?
    
    var onAction: ((AlbumDetailViewModelAction) -> Void)?
    
    private let input = PassthroughSubject<Input, Never>()
    
    private let imageUseCase: PhotoImageUseCase
    private let detailUseCase: FolderDetailUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(folder: Folder,
                imageUseCase: PhotoImageUseCase,
                detailUseCase: FolderDetailUseCase) {
        self.folder = folder
        self.folderName = folder.displayName
        self.imageUseCase = imageUseCase
        self.detailUseCase = detailUseCase
        
        super.init()
        
        self.bind()
    }
    
    public func transform() -> Output {
        return Output(
            name: $folderName.eraseToAnyPublisher(),
            photos: $photos.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher(),
            errorMessage: $errorMessage.eraseToAnyPublisher()
        )
    }
    
    func send(_ input: Input) {
        print("send", input)
        self.input.send(input)
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
    
    private func bind() {
        self.input.sink { [weak self] input in
            guard let self else { return }
            Task { await self.handle(input) }
        }
        .store(in: &cancellables)
    }
    
    private func handle(_ input: Input) async {
        
        switch input {
        case .appear, .refresh:
            await self.loadPhotos()
        case .more:
//            self.showEditView()
            print("more!")
            self.onAction?(.options(folder: self.folder))
        case .dismiss:
            self.onAction?(.pop)
        }
    }
    
    private func loadPhotos() async {
        print("loadPhotos")
        do {
            self.isLoading = true
            let photos = try await self.detailUseCase.fetchPhotos(by: folder.id)
            print("photos count: ", photos.count)
            self.photos = photos
            self.isLoading = false
        } catch {
            
        }
    }
    
    private func changeName(name: String) async {
        do {
            self.isLoading = false
            try await self.detailUseCase.editFolderName(new: name, id: folder.id)
            
            self.folderName = name

            self.isLoading = false
        } catch {
            
        }
    }
    
    private func deleteFolder() {
        print("삭제")
        Task {
            try await detailUseCase.deleteFolder(folder.id)
            self.onAction?(.pop)
        }
    }
}

extension AlbumDetailViewModel: ImageLoadable { }

extension AlbumDetailViewModel: AlbumDetailViewModelDelegate {
    func save(name: String) {
        print("\(name) 저장")
        Task {
            await self.changeName(name: name)
        }
    }
    
    func deleteAlert() {
        showAlert(title: "폴더 삭제",
                  message: "폴더를 삭제 할까요?",
                  buttons: [
                    AlertButtonConfig(title: "취소", style: .default, action: {
                        print("취소")
                    }),
                    AlertButtonConfig(title: "삭제", style: .destructive, action: {
                        self.deleteFolder()
                    })
                  ])
    }
}
