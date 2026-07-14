//
//  TravelPhotoPickerViewModel.swift
//  Presentation
//
//  Created by sanghyeon on 7/12/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Domain

/// 여행 시작일 이전 / 종료일 이후 어느 쪽을 보여줄지 — 정렬 방향과 문구가 서로 반대다
enum TravelPhotoPickerDirection {
    case before(Date)
    case after(Date)

    /// 상단바 아래, 콜렉션뷰 위에 놓이는 안내 문구
    var headerText: String {
        switch self {
        case .before: return "여행 기간 이전 사진"
        case .after: return "여행 기간 다음 사진"
        }
    }
}

@MainActor
final class TravelPhotoPickerViewModel {

    let album: Album
    let direction: TravelPhotoPickerDirection
    /// 이전 단계("이전 사진 선택")에서 이미 골라둔 사진들 — 최종 커밋 때 이번 단계 선택과 합쳐진다
    let carriedSelections: [PhotoInAlbum]

    private let imageUseCase: PhotoImageUseCase
    private let detailUseCase: AlbumDetailUseCase

    private(set) var photos: [PhotoInAlbum] = []
    private(set) var selectedIds: Set<String> = []

    private var page = 1
    private let pageCount = 60
    private var hasNext = true
    private var isLoadingPage = false

    var onPhotosUpdated: (() -> Void)?

    init(album: Album,
         direction: TravelPhotoPickerDirection,
         carriedSelections: [PhotoInAlbum],
         imageUseCase: PhotoImageUseCase,
         detailUseCase: AlbumDetailUseCase) {
        self.album = album
        self.direction = direction
        self.carriedSelections = carriedSelections
        self.imageUseCase = imageUseCase
        self.detailUseCase = detailUseCase
    }

    var selectedPhotos: [PhotoInAlbum] {
        photos.filter { selectedIds.contains($0.localIdentifier) }
    }

    /// carriedSelections + 이번 단계에서 고른 것 — "다음"/"추가"로 넘어갈 때 사용
    var accumulatedSelections: [PhotoInAlbum] {
        carriedSelections + selectedPhotos
    }

    func loadFirstPageIfNeeded() async {
        guard photos.isEmpty else { return }
        await loadNextPage()
    }

    func loadMoreIfNeeded(currentIndex: Int) async {
        guard currentIndex >= photos.count - 12 else { return }
        await loadNextPage()
    }

    private func loadNextPage() async {
        guard hasNext, !isLoadingPage else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }

        do {
            let list: PhotoList
            switch direction {
            case .before(let date):
                list = try await detailUseCase.fetchLibraryPhotos(before: date, page: page, pageCount: pageCount)
            case .after(let date):
                list = try await detailUseCase.fetchLibraryPhotos(after: date, page: page, pageCount: pageCount)
            }
            photos.append(contentsOf: list.photos)
            hasNext = list.hasNext
            page += 1
            onPhotosUpdated?()
        } catch {
            hasNext = false
        }
    }

    func toggleSelection(id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    /// 마지막 단계("다음 사진 선택")에서 "추가" 확정 시 호출
    func commit() async throws {
        try await detailUseCase.addPhotosToAlbum(albumId: album.id, photos: accumulatedSelections)
    }
}

extension TravelPhotoPickerViewModel: ImageLoadable {
    func loadImage(id: String, size: CGSize) async -> UIImage? {
        do {
            guard let cgImage: CGImage = try await imageUseCase.loadImage(id: id, type: .specialSize(size)).cgImage else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
}
