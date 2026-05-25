//
//  ImageViewerViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 5/7/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


//
//  ImageViewerViewModel.swift
//  Presentation
//

import UIKit
import Combine
import Domain

enum ImageViewerViewModelAction {
    case pageChanged(String)
}

final class ImageViewerViewModel: BaseViewModel {

    enum Input {
        case pageChanged(Int)
    }

    struct Output {
        let currentIndex: AnyPublisher<Int, Never>
        let currentPhoto: AnyPublisher<PhotoDetail?, Never>
    }

    // MARK: - Properties
    @Published var currentIndex: Int
    @Published private var currentPhoto: PhotoDetail?
    let photoDetails: [PhotoDetail]
    
    let input = PassthroughSubject<Input, Never>()
    
    var onAction: ((ImageViewerViewModelAction) -> Void)?
    
    private var imageCache: [String: UIImage] = [:]
    private let imageUseCase: ImageViewerUseCase
    
    private var cancellables = Set<AnyCancellable>()

    init(photoDetails: [PhotoDetail], initialIndex: Int,
         imageUseCase: ImageViewerUseCase) {
        self.photoDetails = photoDetails
        self.imageUseCase = imageUseCase
        self.currentIndex = initialIndex
        
        super.init()
        
        self.bind()
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
        case .pageChanged(let index):
            await self.setCurrentPhoto(index: index)
        }
    }
    
    func send(_ input: Input) {
        self.input.send(input)
    }

    func transform() -> Output {
        return Output(
            currentIndex: $currentIndex.eraseToAnyPublisher(),
            currentPhoto: $currentPhoto.eraseToAnyPublisher()
        )
    }
    
    func loadImage(for index: Int, size: CGSize) async -> UIImage? {
        let id = photoDetails[index].id
        return await self.loadImage(id: id, size: size)
    }

    func loadImage(id: String, size: CGSize) async -> UIImage? {
        do {
            if let cached = imageCache[id] { return cached }
            
            guard let cgImage: CGImage = try await imageUseCase.loadImage(
                id: id,
                type: .maxSize
            ).cgImage else {
                return nil
            }
            
            let image = UIImage(cgImage: cgImage)
            imageCache[id] = image
            
            return image
        } catch {
            print("이미지 로딩 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func loadLabels(by id: String) async {
        do {
            let labels = try await imageUseCase.getLabels(by: id)
            self.currentPhoto?.labels = labels
        } catch {
            print("error", error.localizedDescription)
        }
    }
    
    private func setCurrentPhoto(index: Int) async {
        self.currentIndex = index
        let detail = photoDetails[index]
        self.currentPhoto = detail
        await self.loadLabels(by: detail.id)
        self.onAction?(.pageChanged(detail.id))
    }
}

extension ImageViewerViewModel: ImageLoadable {
}
