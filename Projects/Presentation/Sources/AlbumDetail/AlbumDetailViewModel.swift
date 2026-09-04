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
    case pickMergeTarget(candidates: [AlbumMergeCandidate], isTravel: Bool, currentAlbum: Album)
    case pickSplitClusters(clusters: [FaceClusterSummary])
    case pickTravelerManagement(travelers: [Album], others: [Album])
    /// 대표 사진 후보를 골랐을 때 — 실제 적용 전에 미리보기 화면을 띄워달라는 요청
    case previewCover(album: Album, candidateId: String)
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
    func travelerManagementTapped()
    func saveTravelerManagement(travelerIds: [UUID])
    func refreshAfterPhotosAdded()
    /// 대표 사진 미리보기 화면에서 "선택"을 확정했을 때만 실제로 저장
    func setCover(id: String)
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
        /// 대표 사진 고르기 모드에서 사진을 탭했을 때 — 바로 적용하지 않고 미리보기부터 요청
        case selectCoverCandidate(id: String)
    }

    public struct Output {
        let name: AnyPublisher<String, Never>
        let photos: AnyPublisher<[Photo], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let errorMessage: AnyPublisher<String?, Never>
        let selectionMode: AnyPublisher<AlbumDetailPageMode, Never>
        let travelerInfo: AnyPublisher<TravelerInfo?, Never>
        let coverPhotoIdentifier: AnyPublisher<String?, Never>
    }

    /// 여행 헤더에 "이름 문구"와 "인원 수"를 분리해서 보여주기 위한 값
    struct TravelerInfo {
        let name: String
        let count: Int
    }

    @Published private var album: Album
    @Published private var albumName: String
    @Published private var photos: [Photo] = []
    @Published private var errorMessage: String?
    @Published private var selectionMode: AlbumDetailPageMode = .list
    @Published private var travelerInfo: TravelerInfo?
    @Published private var currentCoverId: String?

    var onAction: ((AlbumDetailViewModelAction) -> Void)?

    private let input = PassthroughSubject<Input, Never>()
    private(set) var photoDetails: [PhotoDetail] = []

    private let imageUseCase: PhotoImageUseCase
    private let detailUseCase: AlbumDetailUseCase
    private var cancellables = Set<AnyCancellable>()

    /// 얼굴 앨범 디버깅용: 사진 id별 이 앨범에 묶이게 한 얼굴의 boundingBox
    private var faceBoundingBoxes: [String: CGRect] = [:]
    var isFaceAlbum: Bool { album.from == "face" }
    var isAnimalAlbum: Bool { album.from == "animal" }
    var isTravelAlbum: Bool { album.from == "travel" }
    /// AutoAlbumUseCase의 앨범 명명 기준과 동일하게, 당일치기면 "나들이" 아니면 "여행"
    private var tripSuffix: String {
        guard let start = album.startDate, let end = album.endDate,
              Calendar.current.isDate(start, inSameDayAs: end) else {
            return String(localized: "여행", bundle: .module)
        }
        return String(localized: "나들이", bundle: .module)
    }

    public init(album: Album,
                imageUseCase: PhotoImageUseCase,
                detailUseCase: AlbumDetailUseCase,
                startInSelectionMode: Bool = false) {
        self.album = album
        // 얼굴 앨범은 자동 생성된 이름("인물 3")을 상단 타이틀에 그대로 보여주지 않고,
        // 사용자가 실제로 이름을 지어준 경우에만("isRenamed") 그 이름을 보여준다.
        // 빈 문자열("")을 쓰면 NaviBarView의 스택뷰가 .fillProportionally라 titleLabel의
        // intrinsic width가 0에 가까워지면서 옆 버튼들이 비율을 이상하게 나눠 갖는 버그가 있어서,
        // 공백 한 칸으로 "보이기엔 비어있지만 폭은 0이 아닌" 상태를 만든다 (NaviBarView 자체는 안 건드림)
        self.albumName = Self.computedAlbumName(for: album)
        self.currentCoverId = album.coverPhotoIdentifier
        self.imageUseCase = imageUseCase
        self.detailUseCase = detailUseCase
        self.selectionMode = startInSelectionMode ? .onlySelect : .list
        super.init()
        bind()
    }

    private static func computedAlbumName(for album: Album) -> String {
        ((album.from == "face" || album.from == "animal") && !album.isRenamed) ? " " : album.displayName
    }

    public func transform() -> Output {
        Output(
            name: $albumName.eraseToAnyPublisher(),
            photos: $photos.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher(),
            errorMessage: $errorMessage.eraseToAnyPublisher(),
            selectionMode: $selectionMode.eraseToAnyPublisher(),
            travelerInfo: $travelerInfo.eraseToAnyPublisher(),
            coverPhotoIdentifier: $currentCoverId.eraseToAnyPublisher()
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
            showAlert(
                title: String(localized: "사진 삭제", bundle: .module),
                message: String(localized: "선택한 사진을 삭제할까요?", bundle: .module),
                buttons: [
                    AlertButtonConfig(title: String(localized: "이 앨범에서만 삭제", bundle: .module), style: .default) { [weak self] in
                        Task {
                            await self?.deleteSelected(ids: ids)
                        }
                    },
                    AlertButtonConfig(title: String(localized: "애플 사진 앱에서도 삭제", bundle: .module), style: .default) { [weak self] in
                        Task {
                            await self?.deleteSelected(ids: ids, deleteInLibrary: true)
                        }
                    },
                    AlertButtonConfig(title: String(localized: "취소", bundle: .module), style: .cancel, action: nil)
                ]
            )

        case .selectCoverCandidate(let id):
            onAction?(.previewCover(album: album, candidateId: id))

        case .excludeSelected(let ids):
            showAlert(
                title: String(localized: "다른 사람 인가요?", bundle: .module),
                message: String(localized: "선택한 사진을 앨범에서 제외하고, 다시 묶이지 않게 할게요", bundle: .module),
                buttons: [
                    AlertButtonConfig(title: String(localized: "취소", bundle: .module), style: .cancel, action: nil),
                    AlertButtonConfig(title: String(localized: "제외", bundle: .module), style: .destructive) { [weak self] in
                        Task { await self?.excludeSelected(ids: ids) }
                    }
                ]
            )
        }
    }

    private func loadPhotos() async {
        do {
            isLoading = true
            // 병합처럼 서버 쪽에서 기간/이름이 바뀔 수 있는 작업 후에도 이 화면이 들고 있는 album이
            // 그대로라 사진 추가 등에서 옛 기간을 기준으로 조회하는 문제가 있었다 — 매번 최신으로 갱신
            if let refreshed = try await detailUseCase.fetchAlbum(id: album.id) {
                album = refreshed
                albumName = Self.computedAlbumName(for: album)
                currentCoverId = album.coverPhotoIdentifier
            }
            let photos = try await detailUseCase.fetchPhotos(by: album.id)
            // photos를 publish하면 셀이 바로 loadFaceImage를 호출하므로,
            // faceBoundingBoxes는 그보다 먼저 채워둬야 첫 진입에서도 크롭이 뜬다
            if isFaceAlbum {
                faceBoundingBoxes = try await detailUseCase.fetchFaceBoundingBoxes(clusterId: album.name)
            }
            if isTravelAlbum {
                let linkedFaceAlbums = try await detailUseCase.fetchLinkedFaceAlbums(albumId: album.id)
                let linkedAnimalAlbums = try await detailUseCase.fetchLinkedAnimalAlbums(albumId: album.id)
                travelerInfo = formatTravelerInfo(linkedFaceAlbums + linkedAnimalAlbums)
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

    /// 여행에 등장한 얼굴/동물 앨범들을 "A와 B와 C의 여행"처럼 이름 나열 문구로 만들고, 인원 수는 따로 반환한다.
    /// 이름 지어준 경우는 실제 이름, 아직 안 지어준 경우는 사람은 "사람", 동물은 "반려동물"로 표시한다.
    /// 앨범 기간이 당일치기면(AutoAlbumUseCase의 명명 기준과 동일) "여행" 대신 "나들이"로 표시한다
    private func formatTravelerInfo(_ linkedAlbums: [Album]) -> TravelerInfo? {
        guard !linkedAlbums.isEmpty else { return nil }

        let names = linkedAlbums.map { album -> String in
            if album.isRenamed { return album.displayName }
            return album.from == "animal" ? String(localized: "반려동물", bundle: .module) : String(localized: "사람", bundle: .module)
        }
        let suffix = tripSuffix

        let name: String
        if names.count > 1 {
            let joinedPrefix = names.dropLast()
                .map { String(localized: "\($0)\($0.josa ? "과" : "와")", bundle: .module) }
                .joined(separator: " ")
            name = String(localized: "\(joinedPrefix) \(names.last!)의 \(suffix)", bundle: .module)
        } else {
            name = String(localized: "\(names[0])의 \(suffix)", bundle: .module)
        }

        return TravelerInfo(name: name, count: names.count)
    }

    private func deleteSelected(ids: [String], deleteInLibrary: Bool = false) async {
        do {
            isLoading = true
            try await detailUseCase.deletePhotos(ids, albumId: album.id, deleteInLibrary: deleteInLibrary)
            // 여행 앨범에서 사진을 지웠을 때, 연결된 얼굴/동물 앨범의 사진이 하나도 안 남았으면 그 연결도 같이 해제한다
            if isTravelAlbum {
                try await detailUseCase.pruneLinkedFaceAlbums(albumId: album.id)
                try await detailUseCase.pruneLinkedAnimalAlbums(albumId: album.id)
            }
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
            // album 자체도 갱신해둬야, 다음에 다시 이름 변경 시트를 열었을 때 이전 이름이 아니라
            // 방금 저장한 이름/isRenamed 상태가 정확히 반영된다
            album.displayName = name
            album.isRenamed = true
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func setCoverPhoto(id: String) async {
        do {
            try await detailUseCase.updateCoverPhoto(id: album.id, identifier: id)
            album.coverPhotoIdentifier = id
            currentCoverId = id
        } catch {}
    }

    private func deleteAlbum() {
        isLoading = true
        Task {
            try await detailUseCase.deleteAlbum(album)
            isLoading = false
            onAction?(.pop)
        }
    }

    private func excludeSelected(ids: [String]) async {
        do {
            isLoading = true
            for id in ids {
                if isAnimalAlbum {
                    try await detailUseCase.excludeAnimalPhoto(id, fromAlbumId: album.id)
                } else {
                    try await detailUseCase.excludePhoto(id, fromAlbumId: album.id)
                }
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
                if isTravelAlbum {
                    try await detailUseCase.mergeTravelAlbums(sourceId: album.id, targetId: targetId)
                } else if isAnimalAlbum {
                    try await detailUseCase.mergeAnimalAlbums(sourceId: album.id, targetId: targetId)
                } else {
                    try await detailUseCase.mergeAlbums(sourceId: album.id, targetId: targetId)
                }
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
            if isAnimalAlbum {
                try await detailUseCase.splitAnimalAlbum(albumId: album.id, clusterIds: clusterIds)
            } else {
                try await detailUseCase.splitAlbum(albumId: album.id, clusterIds: clusterIds)
            }
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
            title: String(localized: "앨범 삭제", bundle: .module),
            message: String(localized: "앨범을 삭제 할까요?\n사진은 삭제하지 않아요", bundle: .module),
            buttons: [
                AlertButtonConfig(title: String(localized: "취소", bundle: .module), style: .default, action: {}),
                AlertButtonConfig(title: String(localized: "삭제", bundle: .module), style: .destructive, action: { self.deleteAlbum() })
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
                let candidates: [AlbumMergeCandidate]
                if isTravelAlbum {
                    candidates = try await detailUseCase.fetchOtherTravelAlbums(excluding: album.id)
                } else if isAnimalAlbum {
                    candidates = try await detailUseCase.fetchOtherAnimalAlbums(excluding: album.id)
                } else {
                    candidates = try await detailUseCase.fetchOtherFaceAlbums(excluding: album.id)
                }
                onAction?(.pickMergeTarget(candidates: candidates, isTravel: isTravelAlbum, currentAlbum: album))
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
                let clusters = isAnimalAlbum
                    ? try await detailUseCase.fetchAnimalClusters(albumId: album.id)
                    : try await detailUseCase.fetchClusters(albumId: album.id)
                onAction?(.pickSplitClusters(clusters: clusters))
            } catch {}
        }
    }

    func splitInto(clusterIds: [UUID]) {
        Task { await splitAlbum(clusterIds: clusterIds) }
    }

    func travelerManagementTapped() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let (travelers, others) = try await detailUseCase.fetchTravelerManagementCandidates(albumId: album.id)
                onAction?(.pickTravelerManagement(travelers: travelers, others: others))
            } catch {}
        }
    }

    func saveTravelerManagement(travelerIds: [UUID]) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await detailUseCase.updateLinkedTravelerAlbums(albumId: album.id, albumIds: travelerIds)
                let linkedFaceAlbums = try await detailUseCase.fetchLinkedFaceAlbums(albumId: album.id)
                let linkedAnimalAlbums = try await detailUseCase.fetchLinkedAnimalAlbums(albumId: album.id)
                travelerInfo = formatTravelerInfo(linkedFaceAlbums + linkedAnimalAlbums)
            } catch {}
        }
    }

    func refreshAfterPhotosAdded() {
        send(.refresh)
    }

    func setCover(id: String) {
        Task { await setCoverPhoto(id: id) }
    }
}
