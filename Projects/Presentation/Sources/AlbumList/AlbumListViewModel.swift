//
//  AlbumListViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 6/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import Combine
import UIKit

struct AlbumListData {
    let type: String
    var albums: [AlbumType] = []
}

@MainActor
final class AlbumListViewModel: BaseViewModel {

    enum Input {
        case appear
        case selectItem(Album)
        case dismiss
        case showAlbumMenu(Album)
        case confirmDeleteAlbums([Album])
    }

    struct Output {
        let albumData: AnyPublisher<AlbumListData, Never>
    }

//    @Published private var albums: [Album] = []
    @Published private var albumData: AlbumListData

    let input = PassthroughSubject<Input, Never>()
    var onAction: ((AlbumViewModelAction) -> Void)?

    let from: String
    private let imageUseCase: PhotoImageUseCase
    private let albumUseCase: AlbumUseCase

    private var cancellables = Set<AnyCancellable>()

    init(from: String,
         imageUseCase: PhotoImageUseCase,
         albumUseCase: AlbumUseCase) {

        self.from = from
        self.imageUseCase = imageUseCase
        self.albumUseCase = albumUseCase

        self.albumData = AlbumListData(type: from)

        super.init()

        self.bind()

        // 길게 눌러서 뜨는 앨범 메뉴(삭제/합치기/분리 등)는 이 화면이 아니라 별도로 만든
        // AlbumDetailViewModel을 통해 처리되므로, 이 화면 스스로 다시 불러오지 않으면 반영이 안 된다 —
        // AlbumViewModel(홈 화면)과 동일하게 albumsPublisher를 구독해서 어디서 바뀌든 갱신되게 한다.
        albumUseCase.albumsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.loadAlbumFrom() }
            }
            .store(in: &cancellables)
    }

    func transform() -> Output {
        Output(albumData: $albumData.eraseToAnyPublisher())
    }

    func send(_ input: Input) {
        print("send", input)
        self.input.send(input)
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
        case .appear:
            await self.loadAlbumFrom()
        case .selectItem(let album):
            self.onAction?(.moveDetail(album: album))
        case .dismiss:
            self.onAction?(.pop)
        case .showAlbumMenu(let album):
            self.onAction?(.showAlbumMenu(album))
        case .confirmDeleteAlbums(let albums):
            confirmDeleteAlbums(albums)
        }
    }

    private func confirmDeleteAlbums(_ albums: [Album]) {
        let message = albums.count > 1
            ? "선택한 \(albums.count)개 앨범을 삭제할까요?\n사진은 삭제되지 않아요"
            : "앨범을 삭제 할까요?\n사진은 삭제되지 않아요"
        showAlert(
            title: "앨범 삭제",
            message: message,
            buttons: [
                AlertButtonConfig(title: "취소", style: .default, action: {}),
                AlertButtonConfig(title: "삭제", style: .destructive) { [weak self] in
                    Task { await self?.deleteAlbums(albums) }
                }
            ]
        )
    }

    private func deleteAlbums(_ albums: [Album]) async {
        for album in albums {
            do {
                try await albumUseCase.deleteAlbum(album)
            } catch {
                print("앨범 삭제 실패:", error)
            }
        }
        // 이 ViewModel은 albumsPublisher를 구독하지 않으므로(AlbumViewModel과 달리), 삭제 후
        // 직접 다시 불러와야 목록에서 사라진 게 반영된다
        await loadAlbumFrom()
    }

    private func loadAlbumFrom() async {
        do {
            print("load albums", self.from)
            // "인물" 섹션은 얼굴+동물 두 from을 합쳐서 보여주므로, 홈 화면과 동일하게 둘 다 가져온다
            let albums: [Album]
            if from == "face" {
                let faceAlbums = try await self.albumUseCase.fetchAll(from: "face")
                let animalAlbums = try await self.albumUseCase.fetchAll(from: "animal")
                albums = faceAlbums + animalAlbums
            } else {
                albums = try await self.albumUseCase.fetchAll(from: self.from)
            }
            self.buildSections(from: albums)
        } catch {
            print("loadFodlers error")
        }
    }

    private func buildSections(from albums: [Album]) {

        var list = [AlbumType]()
        switch from {
        case "travel":
            list = albums.filter { $0.from == "travel" }
                .sorted {
                    ($0.startDate ?? Date()) > ($1.startDate ?? Date())
                }
                .map {
                    .travel(TravelAlbumCellViewModel(album: $0, imageLoader: self))
                }

        case "location":
            list = albums.filter { $0.from == "location" }
                .sorted { $0.photoCount > $1.photoCount }
//                .map {
//                    print("displayName", $0.displayName)
//                    //                print("keyword:", $0.keywords.joined(separator: ", "))
//                    return $0
//                }
                .enumerated()
                .map {
                    .location(LocationAlbumCellViewModel(album: $1, imageLoader: self, isMost: $0 == 0))
                }
        case "similar":
            list = albums.filter { $0.from == "similar" }
                .sorted { $0.photoCount > $1.photoCount }
                .map {
                    .similar(SimilarAlbumCellViewModel(album: $0, imageLoader: self))
                }
        case "face":
            list = albums.filter { AlbumSection.faceSectionFromValues.contains($0.from) }
                .sorted { $0.photoCount > $1.photoCount }
                .map { album in
                    album.from == "animal"
                        ? .animal(AnimalAlbumCellViewModel(album: album, imageLoader: self, imageUseCase: imageUseCase, albumUseCase: albumUseCase))
                        : .face(FaceAlbumCellViewModel(album: album, imageLoader: self, imageUseCase: imageUseCase, albumUseCase: albumUseCase))
                }
        default: list = []
        }
//        data.items[.date] = []//albums.filter { $0.from == "date" }
////            .sorted { $0.displayName > $1.displayName }
////            .map {
////                .date(DateAlbumCellViewModel(album: $0, imageLoader: self))
////            }
//        
//        data.items[.location] = albums.filter { $0.from == "location" }
//            .sorted { $0.photoCount > $1.photoCount }
//            .map {
//                print("displayName", $0.displayName)
////                print("keyword:", $0.keywords.joined(separator: ", "))
//                return $0
//            }
//            .prefix(3)
//            .enumerated()
//            .map {
//                .location(LocationAlbumCellViewModel(album: $1, imageLoader: self, isMost: $0 == 0))
//            }
//        
//        data.items[.category] = albums.filter { $0.from == "category" }
//            .sorted { $0.photoCount > $1.photoCount }
//            .map {
//                .category(CategoryAlbumCellViewModel(album: $0, imageLoader: self))
//            }
//        
//        data.items[.face] = albums.filter { $0.from == "face" }
//            .sorted { $0.photoCount > $1.photoCount }
//            .map {
//                .face(FaceCellViewModel(album: $0, imageLoader: self))
//            }
//        
//        data.totalCount = albums.count
        self.albumData = AlbumListData(type: from, albums: list)
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

extension AlbumListViewModel: ImageLoadable {

}
