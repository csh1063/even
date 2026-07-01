//
//  AlbumDetailViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Combine
import Domain

enum AlbumDetailViewModelAction {
    case options(album: Album)
    case pop
    case selectPhoto(_ photoDetails: [PhotoDetail], index: Int, inSelectionMode: Bool)
}

@MainActor
protocol AlbumDetailViewModelDelegate: AnyObject {
    func save(name: String)
    func deleteAlert()
    func changeMode(_ mode: AlbumDetailPageMode)
}

@MainActor
public final class AlbumDetailViewModel: BaseViewModel {

    enum Input {
        case appear
        case refresh
        case more
        case dismiss
        case selectItem(id: String, inSelectionMode: Bool)
        case deleteSelected(ids: [String])
    }

    public struct Output {
        let name: AnyPublisher<String, Never>
        let photos: AnyPublisher<[Photo], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let errorMessage: AnyPublisher<String?, Never>
        let selectionMode: AnyPublisher<AlbumDetailPageMode, Never>
    }

    @Published private var album: Album
    @Published private var albumName: String
    @Published private var photos: [Photo] = []
    @Published private var errorMessage: String?
    @Published private var selectionMode: AlbumDetailPageMode = .list

    var onAction: ((AlbumDetailViewModelAction) -> Void)?

    private let input = PassthroughSubject<Input, Never>()
    private(set) var photoDetails: [PhotoDetail] = []

    private let imageUseCase: PhotoImageUseCase
    private let detailUseCase: AlbumDetailUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(album: Album,
                imageUseCase: PhotoImageUseCase,
                detailUseCase: AlbumDetailUseCase,
                startInSelectionMode: Bool = false) {
        self.album = album
        self.albumName = album.displayName
        self.imageUseCase = imageUseCase
        self.detailUseCase = detailUseCase
        self.selectionMode = startInSelectionMode ? .onlySelect : .list
        super.init()
        bind()
    }

    public func transform() -> Output {
        Output(
            name: $albumName.eraseToAnyPublisher(),
            photos: $photos.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher(),
            errorMessage: $errorMessage.eraseToAnyPublisher(),
            selectionMode: $selectionMode.eraseToAnyPublisher()
        )
    }

    func send(_ input: Input) {
        self.input.send(input)
    }

    func loadImage(id: String, size: CGSize) async -> UIImage? {
        do {
            guard let cgImage: CGImage = try await imageUseCase.loadImage(id: id, type: .specialSize(size)).cgImage else { return nil }
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
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
        case .appear, .refresh:
            await loadPhotos()

        case .more:
            onAction?(.options(album: album))

        case .dismiss:
            onAction?(.pop)

        case .selectItem(let id, let inSelectionMode):
            if let index = photoDetails.firstIndex(where: { $0.id == id }) {
                onAction?(.selectPhoto(photoDetails, index: index, inSelectionMode: inSelectionMode))
            }

        case .deleteSelected(let ids):
            print("삭제?")
            showAlert(
                title: "사진 삭제",
                message: "선택한 사진을 삭제하시겠습니까?",
                buttons: [
                    AlertButtonConfig(title: "이 앨범에서만 삭제", style: .default) { [weak self] in
                        Task {
                            print("삭제!")
//                            self.isLoading = true
                            print("start date!!!:", Date())
                            await self?.deleteSelected(ids: ids)
//                            self.isLoading = false
                            print("end date!!!:", Date())
                        }
                    },
                    AlertButtonConfig(title: "애플 사진 앱에서도 삭제", style: .default) { [weak self] in
                        Task {
                            print("삭제!")
//                            self.isLoading = true
                            print("start date!!!:", Date())
                            await self?.deleteSelected(ids: ids, deleteInLibrary: true)
//                            self.isLoading = false
                            print("end date!!!:", Date())
                        }
                    },
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil),
                ]
            )
        }
    }

    private func loadPhotos() async {
        do {
            isLoading = true
            let photos = try await detailUseCase.fetchPhotos(by: album.id)
            self.photos = photos
            self.photoDetails = photos.map {
                PhotoDetail(id: $0.localIdentifier, createdDate: $0.createdAt, photo: $0)
            }
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func deleteSelected(ids: [String], deleteInLibrary: Bool = false) async {
        do {
            isLoading = true
            try await detailUseCase.deletePhotos(ids, albumId: album.id, deleteInLibrary: deleteInLibrary)
            await loadPhotos()
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func changeName(name: String) async {
        do {
            isLoading = true
            try await detailUseCase.editAlbumName(new: name, id: album.id)
            albumName = name
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func deleteAlbum() {
        isLoading = true
        Task {
            try await detailUseCase.deleteAlbum(album.id)
            isLoading = false
            onAction?(.pop)
        }
    }
}

extension AlbumDetailViewModel: ImageLoadable {}

extension AlbumDetailViewModel: AlbumDetailViewModelDelegate {
    func save(name: String) {
        Task { await changeName(name: name) }
    }

    func deleteAlert() {
        showAlert(
            title: "앨범 삭제",
            message: "앨범을 삭제 할까요?\n실제 사진은 삭제되지 않아요",
            buttons: [
                AlertButtonConfig(title: "취소", style: .default, action: {}),
                AlertButtonConfig(title: "삭제", style: .destructive, action: { self.deleteAlbum() })
            ]
        )
    }

    func changeMode(_ mode: AlbumDetailPageMode) {
        self.selectionMode = mode
    }
}
