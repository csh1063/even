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
    }
    
    struct Output {
        let albumData: AnyPublisher<AlbumListData, Never>
    }
    
//    @Published private var albums: [Album] = []
    @Published private var albumData: AlbumListData
    
    let input = PassthroughSubject<Input, Never>()
    var onAction: ((AlbumViewModelAction) -> Void)?
    
    private let from: String
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
        
//        albumUseCase.albumsPublisher
//            .receive(on: DispatchQueue.main)
//            .handleEvents(receiveOutput: { albums in
//                print("📂 albumsPublisher received: \(albums.count)")
//            })
//            .assign(to: &$albums)
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
        }
    }
    
    private func loadAlbumFrom() async {
        do {
            print("load albums")
            let albums = try await self.albumUseCase.fetchAll()
//            self.albums = albums
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
                .map {
                    print("displayName", $0.displayName)
                    //                print("keyword:", $0.keywords.joined(separator: ", "))
                    return $0
                }
                .enumerated()
                .map {
                    .location(LocationAlbumCellViewModel(album: $1, imageLoader: self, isMost: $0 == 0))
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
