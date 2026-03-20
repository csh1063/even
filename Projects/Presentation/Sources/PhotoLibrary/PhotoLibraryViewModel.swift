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

@MainActor
public final class PhotoLibraryViewModel {
    
    enum Input {
        case appear
        case refresh
        case nextPage(Int)
    }
    
    public struct Output {
        let photos: AnyPublisher<[PhotoInAlbum], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let errorMessage: AnyPublisher<String?, Never>
        let photoPermission: AnyPublisher<PhotoPermission, Never>
    }
 
    // 내부 상태값
//    @Published private var photoList: PhotoList?
    @Published private var photos: [PhotoInAlbum] = []
    @Published private var hasNext: Bool = false
    @Published private var isLoading: Bool = false
    @Published private var errorMessage: String?
    @Published private var photoPermission: PhotoPermission = .notDetermined
    
    private let input = PassthroughSubject<Input, Never>()
    private let usecase: PhotoLibraryUsecase
    private var cancellable = Set<AnyCancellable>()
    
    public init(usecase: PhotoLibraryUsecase) {
        self.usecase = usecase
        self.bind()
    }
    
    public func transform() -> Output {
        return Output(
            photos: $photos.eraseToAnyPublisher(),
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
        self.photoPermission = try await self.usecase.checkPermission()
        return self.photoPermission
    }
    
    func loadImage(id: String, size: CGSize) async -> UIImage? {
        do {
            guard let cgImage: CGImage = try await usecase.loadImage(
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
            await self.loadPhoto(page: 0)
        case let .nextPage(page):
            await self.loadPhoto(page: page)
        }
    }
    
    private func loadPhoto(page: Int) async {
        print("loadPhoto", page)
        do {
            self.isLoading = false
            let photoList = try await self.usecase.fetchData(page: page)
            print("photos count: ", photoList.photos.count)
            self.photos = photoList.photos
            self.hasNext = photoList.hasNext
            self.isLoading = true
        }
        catch {
            
        }
    }
}
