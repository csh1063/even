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
    case moveDetail(album: Album)
    case more(from: String)
    case pop
}

struct AlbumSectionsData {
    var items: [AlbumSection: [AlbumType]] = [:]
    var totalCount: Int = 0

    var isEmpty: Bool {
        items.values.allSatisfy { $0.isEmpty }
    }

    var sections: [AlbumSection] {
        AlbumSection.allCases.filter { items[$0]?.isEmpty == false }
    }
}

@MainActor
public final class AlbumViewModel: BaseViewModel {

    enum Input {
        case appear
        case analysis
        case clear
        case selectItem(Album)
        case more(String)
        case permission
    }

    public struct Output {
        let sections: AnyPublisher<AlbumSectionsData, Never>
        let albums: AnyPublisher<[Album], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let permission: AnyPublisher<PhotoPermission, Never>
    }

    @Published private var sections = AlbumSectionsData()
    @Published private var albums: [Album] = []

    var onAction: ((AlbumViewModelAction) -> Void)?

    let input = PassthroughSubject<Input, Never>()

    private let tabbarViewModel: TabbarViewModel
    private let imageUseCase: PhotoImageUseCase
    private let albumUseCase: AlbumUseCase

    private var cancellables = Set<AnyCancellable>()

    public init(tabbarViewModel: TabbarViewModel,
                imageUseCase: PhotoImageUseCase,
                albumUseCase: AlbumUseCase) {

        self.tabbarViewModel = tabbarViewModel
        self.imageUseCase = imageUseCase
        self.albumUseCase = albumUseCase

        super.init()

        self.bind()

        albumUseCase.albumsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] albums in
                print("📂 albumsPublisher received: \(albums.count)")
                // albums만 갱신하고 끝내면, 실제 화면을 그리는 sections는 그대로라 화면이 안 바뀐다 —
                // 병합/분리처럼 다른 화면에서 syncAlbums()로 밀어준 변경사항이 여기 반영되려면 같이 재빌드해야 한다
                self?.albums = albums
                self?.buildSections(from: albums)
            }
            .store(in: &cancellables)
    }

    public func transform() -> Output {
        return Output(
            sections: $sections.eraseToAnyPublisher(),
            albums: $albums.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher(),
            permission: tabbarViewModel.transform().permission
        )
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

        self.tabbarViewModel.transform()
            .isComplete
            .sink { isComplete in
                if isComplete {
                    self.send(.appear)
                }
            }
            .store(in: &cancellables)
    }

    private func handle(_ input: Input) async {
        switch input {
        case .appear:
            self.isLoading = true
            await self.loadAlbums()
            self.isLoading = false
        case .analysis:
            print("analysis 1")
            tabbarViewModel.send(.analysis)
        case .clear:
            tabbarViewModel.send(.clear)
        case .selectItem(let album):
            print("!!!")
            self.onAction?(.moveDetail(album: album))
        case .more(let type):
            self.onAction?(.more(from: type))
        case .permission:
            tabbarViewModel.send(.permission)
        }
    }

    private func loadAlbums() async {
        do {
            print("load albums")
            let albums = try await self.albumUseCase.fetchAll()
            self.albums = albums

            self.buildSections(from: albums)
        } catch {
            print("loadFodlers error")
        }
    }

    private func buildSections(from albums: [Album]) {

        var data = AlbumSectionsData()

        data.items[.travel] = albums.filter { $0.from == "travel" }
            .sorted {
                ($0.startDate ?? Date()) > ($1.startDate ?? Date())
            }
            .map {
                .travel(TravelAlbumCellViewModel(album: $0, imageLoader: self))
            }

        data.items[.date] = []// albums.filter { $0.from == "date" }
//            .sorted { $0.displayName > $1.displayName }
//            .map {
//                .date(DateAlbumCellViewModel(album: $0, imageLoader: self))
//            }

        data.items[.location] = albums.filter { $0.from == "location" }
            .sorted { $0.photoCount > $1.photoCount }
            .map {
//                print("displayName", $0.displayName)
//                print("keyword:", $0.keywords.joined(separator: ", "))
                return $0
            }
            .prefix(3)
            .enumerated()
            .map {
                .location(LocationAlbumCellViewModel(album: $1, imageLoader: self, isMost: $0 == 0))
            }

        data.items[.category] = albums.filter { $0.from == "category" }
            .sorted { $0.photoCount > $1.photoCount }
            .map {
                .category(CategoryAlbumCellViewModel(album: $0, imageLoader: self))
            }

        data.items[.face] = albums.filter { $0.from == "face" }
            .sorted { $0.photoCount > $1.photoCount }
            .map {
                .face(FaceAlbumCellViewModel(album: $0, imageLoader: self, imageUseCase: imageUseCase, albumUseCase: albumUseCase))
            }

        data.items[.similar] = albums.filter { $0.from == "similar" }
            .sorted { $0.photoCount > $1.photoCount }
            .map {
                .similar(SimilarAlbumCellViewModel(album: $0, imageLoader: self))
            }

        data.totalCount = albums.count

        self.sections = data
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
