//
//  AlbumDetailUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol AlbumDetailUseCase {
    func fetchPhotos(by albumId: UUID) async throws -> [Photo]
    func fetchFaceBoundingBoxes(clusterId: String) async throws -> [String: CGRect]
    func editAlbumName(new name: String, id: UUID) async throws
    func deleteAlbum(_ id: UUID) async throws
    func deletePhotos(_ photoIds: [String], albumId: UUID, deleteInLibrary: Bool) async throws
    func fetchOtherFaceAlbums(excluding albumId: UUID) async throws -> [AlbumMergeCandidate]
    func mergeAlbums(sourceId: UUID, targetId: UUID) async throws
    func excludePhoto(_ photoId: String, fromAlbumId: UUID) async throws
    func fetchClusters(albumId: UUID) async throws -> [FaceClusterSummary]
    func splitAlbum(albumId: UUID, clusterIds: [UUID]) async throws
    func fetchLinkedFaceAlbums(albumId: UUID) async throws -> [Album]
    /// 여행자 관리 시트용 — 전체 얼굴 앨범을 이미 연결된(여행자) / 안 된(인물 앨범) 두 그룹으로 나눠서 반환.
    /// "나"가 아직 연결 안 됐다면 "인물 앨범" 쪽 맨 앞으로
    func fetchFaceAlbumsForTravelerManagement(albumId: UUID) async throws -> (travelers: [Album], others: [Album])
    /// 여행자 관리 시트의 "결정" — 넘긴 id 목록으로 연결 상태를 통째로 교체
    func updateLinkedFaceAlbums(albumId: UUID, faceAlbumIds: [UUID]) async throws

    /// 여행 앨범 "사진 추가" 피커 — 기준 날짜 이전 사진(최신순) / 이후 사진(오래된순)
    func fetchLibraryPhotos(before date: Date, page: Int, pageCount: Int) async throws -> PhotoList
    func fetchLibraryPhotos(after date: Date, page: Int, pageCount: Int) async throws -> PhotoList
    /// 고른 사진들을 앨범에 추가 (아직 분석 안 된 사진이면 기본 정보로 새로 저장) + 등장 인물 얼굴 앨범 자동 연결
    func addPhotosToAlbum(albumId: UUID, photos: [PhotoInAlbum]) async throws
    /// 사진 삭제 후 호출 — 연결된 얼굴 앨범 중 이 앨범에 더 이상 사진이 하나도 안 남은 건 연결 해제
    func pruneLinkedFaceAlbums(albumId: UUID) async throws

    /// 여행 앨범 병합 후보 — 기간이 가까운 다른 여행 앨범 순으로 정렬
    func fetchOtherTravelAlbums(excluding albumId: UUID) async throws -> [AlbumMergeCandidate]
    /// 여행 앨범 병합 — target을 source로 합치고 target은 삭제
    func mergeTravelAlbums(sourceId: UUID, targetId: UUID) async throws
}

public final class DefaultAlbumDetailUseCase: AlbumDetailUseCase {

    private let repository: AlbumDataRepository
    private let libraryRepository: PhotoLibraryRepository
    private let faceClusterRepository: FaceClusterRepository
    private let photoDataRepository: PhotoDataRepository
    private let travelRepository: TravelDetectionRepository

    public init(repository: AlbumDataRepository,
                libraryRepository: PhotoLibraryRepository,
                faceClusterRepository: FaceClusterRepository,
                photoDataRepository: PhotoDataRepository,
                travelRepository: TravelDetectionRepository) {
        self.repository = repository
        self.libraryRepository = libraryRepository
        self.faceClusterRepository = faceClusterRepository
        self.photoDataRepository = photoDataRepository
        self.travelRepository = travelRepository
    }

    public func fetchPhotos(by albumId: UUID) async throws -> [Photo] {
        try repository.fetchPhotos(by: albumId)
    }

    public func fetchFaceBoundingBoxes(clusterId: String) async throws -> [String: CGRect] {
        try repository.fetchFaceBoundingBoxes(clusterId: clusterId)
    }

    public func editAlbumName(new name: String, id: UUID) async throws {
        try repository.updateAlbumName(new: name, id: id)
    }

    public func deleteAlbum(_ id: UUID) async throws {
        try repository.delete(id: id)
    }

    public func deletePhotos(_ photoIds: [String], albumId: UUID, deleteInLibrary: Bool) async throws {
        if deleteInLibrary {
            try await libraryRepository.deletePhotos(by: photoIds)
        }
        try repository.deletePhotos(albumId: albumId, photoIdentifiers: photoIds)
    }

    public func fetchOtherFaceAlbums(excluding albumId: UUID) async throws -> [AlbumMergeCandidate] {
        try await faceClusterRepository.fetchOtherFaceAlbumsSortedBySimilarity(excluding: albumId)
    }

    public func mergeAlbums(sourceId: UUID, targetId: UUID) async throws {
        try await faceClusterRepository.mergeAlbums(sourceId: sourceId, targetId: targetId)
        try repository.syncAlbums()
    }

    public func excludePhoto(_ photoId: String, fromAlbumId: UUID) async throws {
        try await faceClusterRepository.excludePhoto(photoId: photoId, fromAlbumId: fromAlbumId)
        try repository.syncAlbums()
    }

    public func fetchClusters(albumId: UUID) async throws -> [FaceClusterSummary] {
        try await faceClusterRepository.fetchClusters(albumId: albumId)
    }

    public func splitAlbum(albumId: UUID, clusterIds: [UUID]) async throws {
        try await faceClusterRepository.splitAlbum(albumId: albumId, clusterIds: clusterIds)
        try repository.syncAlbums()
    }

    public func fetchLinkedFaceAlbums(albumId: UUID) async throws -> [Album] {
        try repository.fetchLinkedFaceAlbums(albumId: albumId)
    }

    public func fetchFaceAlbumsForTravelerManagement(albumId: UUID) async throws -> (travelers: [Album], others: [Album]) {
        let allFaceAlbums = try repository.fetchAll(from: "face")
        let linkedIds = Set(try repository.fetchLinkedFaceAlbums(albumId: albumId).map { $0.id })

        let travelers = allFaceAlbums.filter { linkedIds.contains($0.id) }
        var others = allFaceAlbums.filter { !linkedIds.contains($0.id) }
        if let meIndex = others.firstIndex(where: { $0.displayName == "나" }) {
            let me = others.remove(at: meIndex)
            others.insert(me, at: 0)
        }
        return (travelers, others)
    }

    public func updateLinkedFaceAlbums(albumId: UUID, faceAlbumIds: [UUID]) async throws {
        try repository.updateLinkedFaceAlbums(albumId: albumId, faceAlbumIds: faceAlbumIds)
    }

    public func fetchLibraryPhotos(before date: Date, page: Int, pageCount: Int) async throws -> PhotoList {
        try await libraryRepository.fetchPhotos(before: date, page: page, pageCount: pageCount)
    }

    public func fetchLibraryPhotos(after date: Date, page: Int, pageCount: Int) async throws -> PhotoList {
        try await libraryRepository.fetchPhotos(after: date, page: page, pageCount: pageCount)
    }

    public func addPhotosToAlbum(albumId: UUID, photos: [PhotoInAlbum]) async throws {
        guard !photos.isEmpty else { return }

        // 아직 한 번도 분석 안 된 사진(스크린샷, 방금 전달받은 사진 등)은 기본 정보로라도 먼저 저장해야
        // 앨범에 연결할 수 있다 (이미 있으면 savePhoto가 조용히 스킵함)
        for photo in photos {
            let basicPhoto = Photo(
                localIdentifier: photo.localIdentifier,
                createdAt: photo.createdDate ?? Date(),
                latitude: photo.latitude,
                longitude: photo.longitude
            )
            try photoDataRepository.savePhoto(photo: basicPhoto)
        }

        let photoIds = photos.map { $0.localIdentifier }
        try repository.addPhotos(albumId: albumId, photoIdentifiers: photoIds)

        // 새로 추가된 사진에 등장하는 얼굴이 있으면 그 얼굴 앨범들도 여행자로 자동 연결
        let newFaceAlbumIds = try await faceClusterRepository.fetchFaceAlbumIds(forPhotoIds: photoIds)
        guard !newFaceAlbumIds.isEmpty else { return }

        let currentLinkedIds = try repository.fetchLinkedFaceAlbums(albumId: albumId).map { $0.id }
        let union = Array(Set(currentLinkedIds).union(newFaceAlbumIds))
        try repository.updateLinkedFaceAlbums(albumId: albumId, faceAlbumIds: union)
    }

    public func pruneLinkedFaceAlbums(albumId: UUID) async throws {
        let remainingPhotoIds = Set(try repository.fetchPhotos(by: albumId).map { $0.localIdentifier })
        let linkedFaceAlbums = try repository.fetchLinkedFaceAlbums(albumId: albumId)

        var keptIds: [UUID] = []
        for faceAlbum in linkedFaceAlbums {
            let facePhotoIds = Set(try repository.fetchPhotos(by: faceAlbum.id).map { $0.localIdentifier })
            if !facePhotoIds.isDisjoint(with: remainingPhotoIds) {
                keptIds.append(faceAlbum.id)
            }
        }
        try repository.updateLinkedFaceAlbums(albumId: albumId, faceAlbumIds: keptIds)
    }

    public func fetchOtherTravelAlbums(excluding albumId: UUID) async throws -> [AlbumMergeCandidate] {
        try repository.fetchOtherTravelAlbums(excluding: albumId)
    }

    /// source(현재 보고 있는 앨범)를 살리고 target을 삭제하는 방향으로 합친다.
    /// 두 여행 기간 사이(위치가 안 잡혀 클러스터링에서 빠졌던 사진들 포함)를 전부 다시 모아서
    /// 사진/기간/이름/연결된 얼굴 앨범을 AutoAlbumUseCase와 동일한 알고리즘으로 다시 계산한다
    public func mergeTravelAlbums(sourceId: UUID, targetId: UUID) async throws {
        let travelAlbums = try repository.fetchAll(from: "travel")
        guard let source = travelAlbums.first(where: { $0.id == sourceId }),
              let target = travelAlbums.first(where: { $0.id == targetId }) else { return }

        let starts = [source.startDate, target.startDate].compactMap { $0 }
        let ends = [source.endDate, target.endDate].compactMap { $0 }
        guard let mergedStart = starts.min(), let mergedEnd = ends.max() else { return }

        let photosInRange = try photoDataRepository.fetchPhotos(from: mergedStart, to: mergedEnd)
        let photoIdentifiers = photosInRange.map { $0.localIdentifier }

        // 대표 주소는 위치가 있는 사진만으로 계산 (위치 없는 사진을 그대로 넘기면 (0,0) 근처로 잘못 지오코딩될 수 있음)
        let geoSnapshots = photosInRange
            .filter { ($0.latitude ?? 0) != 0 || ($0.longitude ?? 0) != 0 }
            .map { PhotoLocationSnapshot(from: $0) }
        let cluster = try? await travelRepository.buildCluster(from: geoSnapshots)

        let displayName: String
        if let cluster {
            let place = TravelAlbumNaming.cleanAreaName(cluster.address, isoCode: cluster.isoCountryCode)
            displayName = TravelAlbumNaming.displayName(place: place, startDate: mergedStart, endDate: mergedEnd)
        } else {
            displayName = source.displayName
        }

        // 연결된 얼굴 앨범도 기존 것들의 합집합이 아니라, 새로 모인 전체 사진 기준으로 다시 계산
        let mergedPhotoIdSet = Set(photoIdentifiers)
        let faceAlbums = try repository.fetchAll(from: "face")
        let linkedFaceAlbumIds = try faceAlbums
            .filter { faceAlbum in
                let facePhotoIds = Set(try repository.fetchPhotos(by: faceAlbum.id).map { $0.localIdentifier })
                return !facePhotoIds.isDisjoint(with: mergedPhotoIdSet)
            }
            .map { $0.id }

        try repository.mergeTravelAlbums(
            sourceId: sourceId,
            targetId: targetId,
            photoIdentifiers: photoIdentifiers,
            startDate: mergedStart,
            endDate: mergedEnd,
            displayName: displayName,
            linkedFaceAlbumIds: linkedFaceAlbumIds
        )
        try repository.syncAlbums()
    }
}
