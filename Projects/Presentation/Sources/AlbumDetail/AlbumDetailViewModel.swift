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
    
    private var cancellable = Set<AnyCancellable>()
    
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
        .store(in: &cancellable)
    }
    
    private func handle(_ input: Input) async {
        
        switch input {
        case .appear, .refresh:
            await self.loadPhotos()
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
}

extension AlbumDetailViewModel: ImageLoadable { }
