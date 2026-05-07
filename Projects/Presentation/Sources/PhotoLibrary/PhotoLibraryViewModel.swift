//
//  PhotoLibraryViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation
import Combine
import Domain
import UIKit

protocol PhotoLibraryViewModelAction {
    func move(_ photo: Photo)
}

@MainActor
public final class PhotoLibraryViewModel: BaseViewModel {
    
    enum Input {
        case appear
        case refresh
        case nextPage(Int)
        case selectCell(PhotoCellItemViewModel)
    }
    
    public struct Output {
        let photos: AnyPublisher<[PhotoHeader: [PhotoCellItemViewModel]], Never>
        let totalCount: AnyPublisher<Int, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let errorMessage: AnyPublisher<String?, Never>
        let photoPermission: AnyPublisher<PhotoPermission, Never>
    }
 
    // 내부 상태값
    @Published private var photos: [PhotoHeader: [PhotoCellItemViewModel]] = [:]
    @Published private var totalCount: Int = 0
    @Published private var hasNext: Bool = false
    @Published private var errorMessage: String?
    @Published private var photoPermission: PhotoPermission = .notDetermined
    
    private var photoList: [Photo] = []
    
    private let input = PassthroughSubject<Input, Never>()
    private let useCase: PhotoLibraryUseCase
    private let imageUseCase: PhotoImageUseCase
    private var cancellables = Set<AnyCancellable>()
    
    var onAction: ((PhotoLibraryViewModelAction) -> Void)?
    
    public init(useCase: PhotoLibraryUseCase,
                imageUseCase: PhotoImageUseCase) {
        self.useCase = useCase
        self.imageUseCase = imageUseCase
        
        super.init()
        
        var items = [PhotoCellItemViewModel]()
        
        for i in 0..<20 {
            items.append(PhotoCellItemViewModel(localIdentifier: "\(i)", imageLoader: self))
        }
        
        self.photos = [PhotoHeader(title: "-", count: 0):items]
        
        self.bind()
    }
    
    public func transform() -> Output {
        return Output(
            photos: $photos.eraseToAnyPublisher(),
            totalCount: $totalCount.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher(),
            errorMessage: $errorMessage.eraseToAnyPublisher(),
            photoPermission: $photoPermission.eraseToAnyPublisher()
        )
    }
    
    func send(_ input: Input) {
        print("send", input)
        self.input.send(input)
    }
    
    func checkPermission() async throws -> PhotoPermission {
        self.photoPermission = try await self.useCase.checkPermission()
        return self.photoPermission
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
            await self.loadPhoto(page: 0)
        case let .nextPage(page):
            await self.loadPhoto(page: page)
        case .selectCell(let data):
            break
//            self.onAction?()
        }
    }
    
    private func loadPhoto(page: Int) async {
        print("loadPhoto", page)
        do {
            self.isLoading = false
            let photoList = try await self.useCase.fetchData(page: page)
            print("photos count: ", photoList.photos.count)
            
//            self.photos = photoList.photos
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 MM월"
            formatter.locale = Locale(identifier: "ko_KR")
            let grouped = Dictionary(grouping: photoList.photos) { photo in
                photo.createdDate.map { formatter.string(from: $0) } ?? "날짜 없음"
            }
            self.totalCount = photoList.photos.count
            self.photos = Dictionary(uniqueKeysWithValues: grouped.map { key, values in
                (
                    PhotoHeader(title: key, count: values.count),
                    values.map {
                        PhotoCellItemViewModel(
                            localIdentifier: $0.localIdentifier,
                            imageLoader: self,
                            isUnanalysis: $0.isUnanalysis
                        )
                    }
                )
            })
            
            self.hasNext = photoList.hasNext
            
            self.isLoading = true
        } catch {
            
        }
    }
}

extension PhotoLibraryViewModel: ImageLoadable { }
