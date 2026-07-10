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
    case pickMergeTarget(candidates: [AlbumMergeCandidate])
    case pickSplitClusters(clusters: [FaceClusterSummary])
}

@MainActor
protocol AlbumDetailViewModelDelegate: AnyObject {
    func save(name: String)
    func deleteAlert()
    func changeMode(_ mode: AlbumDetailPageMode)
    func mergeTapped()
    func mergeInto(albumIds: [UUID])
    func splitTapped()
    func splitInto(clusterIds: [UUID])
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
        case excludeSelected(ids: [String])
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

    /// 얼굴 앨범 디버깅용: 사진 id별 이 앨범에 묶이게 한 얼굴의 boundingBox
    private var faceBoundingBoxes: [String: CGRect] = [:]
    var isFaceAlbum: Bool { album.from == "face" }

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

    /// 얼굴 앨범 디버깅용: 전체 사진이 아니라 이 앨범에 묶이게 한 얼굴 부분만 크롭해서 반환
    func loadFaceImage(id: String, size: CGSize) async -> UIImage? {
        guard let boundingBox = faceBoundingBoxes[id] else {
            return await loadImage(id: id, size: size)
        }
        do {
            guard let cgImage: CGImage = try await imageUseCase.loadImage(id: id, type: .specialSize(size)).cgImage,
                  let cropped = crop(cgImage, to: boundingBox) else { return nil }
            return UIImage(cgImage: cropped)
        } catch {
            return nil
        }
    }

    /// boundingBox는 Vision 정규화 좌표(원점 좌하단, 0~1) 기준
    private func crop(_ image: CGImage, to boundingBox: CGRect) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        let scale: CGFloat = 1.1
        let expandedWidth = boundingBox.width * scale
        let expandedHeight = boundingBox.height * scale
        let expandedX = boundingBox.minX - (expandedWidth - boundingBox.width) / 2
        let expandedY = boundingBox.minY - (expandedHeight - boundingBox.height) / 2

        let clampedX = max(0, expandedX)
        let clampedY = max(0, expandedY)
        let clampedWidth = min(expandedWidth, 1.0 - clampedX)
        let clampedHeight = min(expandedHeight, 1.0 - clampedY)

        let rect = CGRect(
            x: clampedX * width,
            y: (1.0 - clampedY - clampedHeight) * height,
            width: clampedWidth * width,
            height: clampedHeight * height
        )
        return image.cropping(to: rect)
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
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil)
                ]
            )

        case .excludeSelected(let ids):
            showAlert(
                title: "다른 사람 인가요?",
                message: "선택한 사진을 앨범에서 제외하고, 다시 묶이지 않게 할게요",
                buttons: [
                    AlertButtonConfig(title: "취소", style: .cancel, action: nil),
                    AlertButtonConfig(title: "제외", style: .destructive) { [weak self] in
                        Task { await self?.excludeSelected(ids: ids) }
                    }
                ]
            )
        }
    }

    private func loadPhotos() async {
        do {
            isLoading = true
            let photos = try await detailUseCase.fetchPhotos(by: album.id)
            // photos를 publish하면 셀이 바로 loadFaceImage를 호출하므로,
            // faceBoundingBoxes는 그보다 먼저 채워둬야 첫 진입에서도 크롭이 뜬다
            if isFaceAlbum {
                faceBoundingBoxes = try await detailUseCase.fetchFaceBoundingBoxes(clusterId: album.name)
            }
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

    private func excludeSelected(ids: [String]) async {
        do {
            isLoading = true
            for id in ids {
                try await detailUseCase.excludePhoto(id, fromAlbumId: album.id)
            }
            await loadPhotos()
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func mergeAlbums(targetAlbumIds: [UUID]) async {
        do {
            isLoading = true
            for targetId in targetAlbumIds {
                try await detailUseCase.mergeAlbums(sourceId: album.id, targetId: targetId)
            }
            await loadPhotos()
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func splitAlbum(clusterIds: [UUID]) async {
        do {
            isLoading = true
            try await detailUseCase.splitAlbum(albumId: album.id, clusterIds: clusterIds)
            await loadPhotos()
            isLoading = false
        } catch {
            isLoading = false
        }
    }
}

extension AlbumDetailViewModel: ImageLoadable {}

/// 얼굴 앨범 디버깅용: 전체 사진 대신 얼굴 크롭 이미지를 반환하는 로더
struct FaceAlbumImageLoader: ImageLoadable {
    private let viewModel: AlbumDetailViewModel

    init(viewModel: AlbumDetailViewModel) {
        self.viewModel = viewModel
    }

    func loadImage(id: String, size: CGSize) async -> UIImage? {
        await viewModel.loadFaceImage(id: id, size: size)
    }
}

extension AlbumDetailViewModel: AlbumDetailViewModelDelegate {
    func save(name: String) {
        Task { await changeName(name: name) }
    }

    func deleteAlert() {
        showAlert(
            title: "앨범 삭제",
            message: "앨범을 삭제 할까요?\n사진은 삭제되지 않아요",
            buttons: [
                AlertButtonConfig(title: "취소", style: .default, action: {}),
                AlertButtonConfig(title: "삭제", style: .destructive, action: { self.deleteAlbum() })
            ]
        )
    }

    func changeMode(_ mode: AlbumDetailPageMode) {
        self.selectionMode = mode
    }

    func mergeTapped() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let candidates = try await detailUseCase.fetchOtherFaceAlbums(excluding: album.id)
                onAction?(.pickMergeTarget(candidates: candidates))
            } catch {}
        }
    }

    func mergeInto(albumIds: [UUID]) {
        Task { await mergeAlbums(targetAlbumIds: albumIds) }
    }

    func splitTapped() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let clusters = try await detailUseCase.fetchClusters(albumId: album.id)
                onAction?(.pickSplitClusters(clusters: clusters))
            } catch {}
        }
    }

    func splitInto(clusterIds: [UUID]) {
        Task { await splitAlbum(clusterIds: clusterIds) }
    }
}
