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

struct AlbumSectionsData {
    var items: [AlbumSection: [AlbumType]] = [:]
    var totalCount: Int = 0

    var sections: [AlbumSection] {
        AlbumSection.allCases.filter { items[$0]?.isEmpty == false }
    }
}

//struct AlbumSectionsData {
//    
//    var sections: [AlbumSection] {
//        var result = [AlbumSection]()
//        
//        if !travelItems.isEmpty {
//            result.append(.travel)
//        }
//        
//        if !dateItems.isEmpty {
//            result.append(.date)
//        }
//        
//        if !locationItems.isEmpty {
//            result.append(.location)
//        }
//        
//        if !categoryItems.isEmpty {
//            result.append(.category)
//        }
//        
//        if !faceItems.isEmpty {
//            result.append(.face)
//        }
//        
//        return result
//    }
//    
//    var dateItems:     [DateAlbumCellViewModel]   = []
//    var travelItems:     [TravelAlbumCellViewModel]  = []
//    var locationItems:  [LocationAlbumCellViewModel]    = []
//    var categoryItems: [CategoryAlbumCellViewModel]   = []
//    var faceItems:     [FaceCellViewModel]       = []
//    
//    var totalCount: Int = 0
//}

@MainActor
public final class AlbumViewModel: BaseViewModel {
    
    enum Input {
        case appear
        case analysis
        case clear
        case selectItem(Folder)
        case permission
    }
    
    public struct Output {
        let sections: AnyPublisher<AlbumSectionsData, Never>
        let folders: AnyPublisher<[Folder], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let permission: AnyPublisher<PhotoPermission, Never>
    }
    
    @Published private var sections = AlbumSectionsData()
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
            .handleEvents(receiveOutput: { folders in
                print("📂 foldersPublisher received: \(folders.count)")
            })
            .assign(to: &$folders)
    }
    
    public func transform() -> Output {
        return Output(
            sections: $sections.eraseToAnyPublisher(),
            folders: $folders.eraseToAnyPublisher(),
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
        
//        tabbarViewModel.transform().permission
//            .sink { permission in
//                self.permission = permission
//            }
//            .store(in: &cancellables)
    }
    
    private func handle(_ input: Input) async {
        switch input {
        case .appear:
            self.isLoading = true
            await self.loadFodlers()
            self.isLoading = false
        case .analysis:
            print("analysis 1")
            tabbarViewModel.send(.analysis)
        case .clear:
            tabbarViewModel.send(.clear)
        case .selectItem(let folder):
            print("!!!")
            self.onAction?(.moveDetail(folder: folder))
        case .permission:
            tabbarViewModel.send(.permission)
        }
    }
    
    private func loadFodlers() async {
        do {
            print("load folders")
            let folders = try await self.folderUseCase.fetchAll()
            self.folders = folders
            
            self.buildSections(from: folders)
        } catch {
            print("loadFodlers error")
        }
    }
    
    private func buildSections(from folders: [Folder]) {
        
        var data = AlbumSectionsData()
        
        data.items[.travel] = folders.filter { $0.from == "travel" }
            .sorted {
                $0.startDate > $1.startDate
            }
            .map {
                .travel(TravelAlbumCellViewModel(folder: $0, imageLoader: self))
            }
        
        data.items[.date] = folders.filter { $0.from == "date" }
            .sorted { $0.displayName > $1.displayName }
            .map {
                .date(DateAlbumCellViewModel(folder: $0, imageLoader: self))
            }
        
        data.items[.location] = folders.filter { $0.from == "location" }
            .sorted { $0.photoCount > $1.photoCount }
            .map {
//                print("keyword:", $0.keywords.joined(separator: ", "))
                return $0
            }
            .prefix(3)
            .enumerated()
            .map {
                .location(LocationAlbumCellViewModel(folder: $1, imageLoader: self, isMost: $0 == 0))
            }
        
        data.items[.category] = folders.filter { $0.from == "category" }
            .sorted { $0.photoCount > $1.photoCount }
            .map {
                .category(CategoryAlbumCellViewModel(folder: $0, imageLoader: self))
            }
        
        data.items[.face] = folders.filter { $0.from == "face" }
            .sorted { $0.photoCount > $1.photoCount }
            .map {
                .face(FaceCellViewModel(folder: $0, imageLoader: self))
            }
        
        data.totalCount = folders.count
 
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
