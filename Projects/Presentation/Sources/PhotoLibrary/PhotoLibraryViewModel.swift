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

enum PhotoLibraryViewModelAction {
    case selectPhoto(_ photoDetails: [PhotoDetail], index: Int)
}

@MainActor
public final class PhotoLibraryViewModel: BaseViewModel {

    enum Input {
        case appear
        case refresh
        case permission
        case selectItem(id: String)
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

    private var photoDetails: [PhotoDetail] = []
    private var isRefresh: Bool = false

    private let input = PassthroughSubject<Input, Never>()

    private let tabbarViewModel: TabbarViewModel
    private let useCase: PhotoLibraryUseCase
    private let imageUseCase: PhotoImageUseCase
    private var cancellables = Set<AnyCancellable>()

    var onAction: ((PhotoLibraryViewModelAction) -> Void)?

    public init(tabbarViewModel: TabbarViewModel,
                useCase: PhotoLibraryUseCase,
                imageUseCase: PhotoImageUseCase) {
        self.tabbarViewModel = tabbarViewModel
        self.useCase = useCase
        self.imageUseCase = imageUseCase

        super.init()

        var items = [PhotoCellItemViewModel]()

        for i in 0..<20 {
            items.append(PhotoCellItemViewModel(localIdentifier: "\(i)", imageLoader: self))
        }

        self.photos = [PhotoHeader(title: "-", count: 0): items]

        self.bind()
    }

    public func transform() -> Output {
        return Output(
            photos: $photos.eraseToAnyPublisher(),
            totalCount: $totalCount.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher(),
            errorMessage: $errorMessage.eraseToAnyPublisher(),
            photoPermission: tabbarViewModel.transform().permission
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
        case .appear:
            await self.loadPhoto()
        case .refresh:
            self.isRefresh = true
            await self.loadPhoto()
        case .permission:
            tabbarViewModel.send(.permission)
        case .selectItem(let id):
            if let index = self.photoDetails.firstIndex(where: {$0.id == id}) {
                self.onAction?(.selectPhoto(self.photoDetails, index: index))
            }
        }
    }

    private func loadPhoto() async {
        print("loadPhoto")
        defer {
            if isRefresh {
                self.isLoading = false
            }

            self.isRefresh = false
        }
        do {
            if isRefresh {
                self.isLoading = true
            }
            let photoList = try await self.useCase.fetchPhoto()
            print("photos count: ", photoList.photos.count)

            self.photoDetails = photoList.photos.map {
                PhotoDetail(id: $0.localIdentifier, createdDate: $0.createdDate, photo: $0.photo)
            }
//            self.photoMap = Dictionary(uniqueKeysWithValues: photoList.photos.compactMap{$0.photo}.map { ($0.localIdentifier, $0) })
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 MM월"
            formatter.locale = Locale(identifier: "ko_KR")
            let grouped = Dictionary(grouping: photoList.photos) { photo in
                photo.createdDate.map { formatter.string(from: $0) } ?? "날짜 없음"
            }
            self.totalCount = photoList.totalCount
            self.photos = Dictionary(uniqueKeysWithValues: grouped.map { key, values in
                (
                    PhotoHeader(title: key, count: values.count),
                    values.map {
                        PhotoCellItemViewModel(
                            localIdentifier: $0.localIdentifier,
                            imageLoader: self,
                            isUnanalysis: $0.photo == nil
                        )
                    }
                )
            })

            self.hasNext = photoList.hasNext
        } catch {

        }
    }
}

extension PhotoLibraryViewModel: ImageLoadable { }
