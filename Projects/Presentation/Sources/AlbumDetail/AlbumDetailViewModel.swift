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
    case options(album: Album)
    case pop
    case selectPhoto(_ photoDetails: [PhotoDetail], index: Int)
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
        case selectItem(id: String)
    }
    
    public struct Output {
        let name: AnyPublisher<String, Never>
        let photos: AnyPublisher<[Photo], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let errorMessage: AnyPublisher<String?, Never>
    }
 
    // 내부 상태값
//    @Published private var photoList: PhotoList?
    @Published private var album: Album
    @Published private var albumName: String
    @Published private var photos: [Photo] = []
    @Published private var hasNext: Bool = false
    @Published private var errorMessage: String?
    
    var onAction: ((AlbumDetailViewModelAction) -> Void)?
    
    private let input = PassthroughSubject<Input, Never>()
    private var photoDetails: [PhotoDetail] = []
    
    private let imageUseCase: PhotoImageUseCase
    private let detailUseCase: AlbumDetailUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(album: Album,
                imageUseCase: PhotoImageUseCase,
                detailUseCase: AlbumDetailUseCase) {
        self.album = album
        self.albumName = album.displayName
        self.imageUseCase = imageUseCase
        self.detailUseCase = detailUseCase
        
        super.init()
        
        var items = [Photo]()
        
        for i in 0..<20 {
            items.append(Photo(localIdentifier: "\(i)"))
        }
        
        self.photos = items
        
        self.bind()
    }
    
    public func transform() -> Output {
        return Output(
            name: $albumName.eraseToAnyPublisher(),
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
            Task { @MainActor in await self.handle(input) }
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
            self.onAction?(.options(album: self.album))
        case .dismiss:
            self.onAction?(.pop)
        case .selectItem(let id):
            if let index = self.photoDetails.firstIndex(where: {$0.id == id}) {
                self.onAction?(.selectPhoto(self.photoDetails, index: index))
            }
        }
    }
    
    private func loadPhotos() async {
        print("loadPhotos")
        do {
            self.isLoading = true
            let photos = try await self.detailUseCase.fetchPhotos(by: album.id)
            print("photos count: ", photos.count)
            self.photos = photos
            
            self.photoDetails = photos.map {
                PhotoDetail(id: $0.localIdentifier, createdDate: $0.createdAt, photo: $0)
            }
            self.isLoading = false
        } catch {
            
        }
    }
    
    private func changeName(name: String) async {
        do {
            self.isLoading = true
            try await self.detailUseCase.editAlbumName(new: name, id: album.id)
            
            self.albumName = name

            self.isLoading = false
        } catch {
            
        }
    }
    
    private func deleteAlbum() {
        print("삭제")
        self.isLoading = true
        Task {
            try await detailUseCase.deleteAlbum(album.id)
            self.isLoading = false
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
                        self.deleteAlbum()
                    })
                  ])
    }
}
