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

    /// 헤더 토글 버튼에 쓰이는 문구
    var headerText: String {
        switch self {
        case .before: return String(localized: "여행 기간 이전", bundle: .module)
        case .after: return String(localized: "여행 기간 이후", bundle: .module)
        }
    }
}

@MainActor
final class TravelPhotoPickerViewModel {

    let album: Album
    let direction: TravelPhotoPickerDirection

    private let imageUseCase: PhotoImageUseCase
    private let detailUseCase: AlbumDetailUseCase

    private(set) var photos: [PhotoInAlbum] = []
    private(set) var selectedIds: Set<String> = []

    private var page = 1
    private let pageCount = 60
    private var hasNext = true
    private var isLoadingPage = false

    var onPhotosUpdated: (() -> Void)?
    /// 이전/이후 선택 상태가 바뀔 때마다 알려서, 화면 쪽에서 "추가" 버튼 활성화 여부를 갱신할 수 있게 한다
    var onSelectionChanged: (() -> Void)?

    init(album: Album,
         direction: TravelPhotoPickerDirection,
         imageUseCase: PhotoImageUseCase,
         detailUseCase: AlbumDetailUseCase) {
        self.album = album
        self.direction = direction
        self.imageUseCase = imageUseCase
        self.detailUseCase = detailUseCase
    }

    var selectedPhotos: [PhotoInAlbum] {
        photos.filter { selectedIds.contains($0.localIdentifier) }
    }

    /// 상세(뷰어) 화면에 넘겨줄 목록 — 앨범 상세와 동일하게 이미지를 탭하면 상세로 볼 수 있게 한다
    var photoDetails: [PhotoDetail] {
        photos.map { PhotoDetail(id: $0.localIdentifier, createdDate: $0.createdDate, photo: $0.photo) }
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
        onSelectionChanged?()
    }

    /// 상세(뷰어)에서 선택 상태를 바꾸고 돌아왔을 때 그리드에도 반영
    func syncSelection(_ identifiers: Set<String>) {
        selectedIds = identifiers
        onSelectionChanged?()
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
