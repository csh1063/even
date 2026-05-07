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

final class ImageViewerViewModel {

    // MARK: - Input

    struct Input {
        let pageChanged: AnyPublisher<Int, Never>
    }

    // MARK: - Output

    struct Output {
        let currentPhoto: AnyPublisher<Photo, Never>
    }

    // MARK: - Properties

    let photos: [Photo]
    let initialIndex: Int
    private let imageLoader: any ImageLoadable
    private var imageCache: [String: UIImage] = [:]
    private let currentIndexSubject: CurrentValueSubject<Int, Never>
    private var cancellables = Set<AnyCancellable>()

    init(photos: [Photo], initialIndex: Int, imageLoader: any ImageLoadable) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.imageLoader = imageLoader
        self.currentIndexSubject = CurrentValueSubject(initialIndex)
    }

    func transform(input: Input) -> Output {
        input.pageChanged
            .sink { [weak self] index in
                self?.currentIndexSubject.send(index)
            }
            .store(in: &cancellables)

        let currentPhoto = currentIndexSubject
            .map { [weak self] index -> Photo in
                self?.photos[index] ?? self!.photos[0]
            }
            .eraseToAnyPublisher()

        return Output(currentPhoto: currentPhoto)
    }

    func loadImage(for index: Int, size: CGSize) async -> UIImage? {
        let id = photos[index].localIdentifier
        if let cached = imageCache[id] { return cached }
        let image = await imageLoader.loadImage(id: id, size: size)
        if let image { imageCache[id] = image }
        return image
    }

    var currentPhoto: Photo {
        photos[currentIndexSubject.value]
    }
}
