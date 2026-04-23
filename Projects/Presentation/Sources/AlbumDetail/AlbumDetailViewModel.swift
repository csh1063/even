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

@MainActor
public final class AlbumDetailViewModel: BaseViewModel {
    
    enum Input {
        case appear
        case refresh
        case edit
        case delete
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
    
    private let input = PassthroughSubject<Input, Never>()
    
    private let libraryUseCase: PhotoLibraryUseCase
    private let detailUseCase: FolderDetailUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    var pop: (() -> Void)?
    
    public init(folder: Folder,
                libraryUseCase: PhotoLibraryUseCase,
                detailUseCase: FolderDetailUseCase,
                pop: @escaping () -> Void) {
        self.folder = folder
        self.folderName = folder.displayName
        self.libraryUseCase = libraryUseCase
        self.detailUseCase = detailUseCase
        
        super.init()
        
        self.bind()
        self.pop = pop
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
            guard let cgImage: CGImage = try await libraryUseCase.loadImage(
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
        case .edit:
            self.showEditView()
        case .delete:
            self.deleteAlert()
        }
    }
    
    private func loadPhotos() async {
        print("loadPhotos")
        do {
            self.isLoading = false
            let photos = try await self.detailUseCase.fetchPhotos(by: folder.id)
            print("photos count: ", photos.count)
            self.photos = photos
            self.isLoading = true
        } catch {
            
        }
    }
    
    private func showEditView() {
        print("showEditView!!")
    }
    
    private func deleteAlert() {
        showAlert(title: "폴더 삭제",
                  message: "폴더를 삭제 할까요?",
                  buttons: [
                    AlertButtonConfig(title: "취소", style: .default, action: {
                        print("취소")
                    }),
                    AlertButtonConfig(title: "삭제", style: .destructive, action: {
                        print("삭제")
                    })
                  ])
    }
}

extension AlbumDetailViewModel: ImageLoadable { }
