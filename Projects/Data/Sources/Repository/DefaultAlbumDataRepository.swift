//
//  DefaultAlbumDataRepository.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import SwiftData
import Domain
import Combine

public final class DefaultAlbumDataRepository: AlbumDataRepository {

    private let container: ModelContainer

    private let albumsSubject = CurrentValueSubject<[Album], Never>([])
    public var albumsPublisher: AnyPublisher<[Album], Never> {
        albumsSubject.eraseToAnyPublisher()
    }

    public init(container: ModelContainer) {
        self.container = container
    }

    public func saveAlbum(album: Album, returnExist: Bool = false) throws -> Album? {

        let context = ModelContext(container)

        let name = album.name
        let from = album.from
        let fetchDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.name == name && $0.from == from }
        )

        let existing = try context.fetch(fetchDescriptor)
        guard existing.isEmpty else { return returnExist ? existing.first?.toDomain():nil }

        let entity = AlbumEntity(
            id: album.id,
            name: album.name,
            displayName: album.displayName,
            isAuto: album.isAuto,
            coverPhotoIdentifier: album.coverPhotoIdentifier,
            from: album.from
        )
        context.insert(entity)

        album.keywords.forEach {
            let keywordEntity = AlbumKeywordEntity(
                keyword: $0,
                weight: 1.0,
                album: entity
            )
            context.insert(keywordEntity)
        }

        try context.save()
        return album
    }

    public func fetchAll() throws -> [Album] {

        let context = ModelContext(container)

        let fetchDescriptor = FetchDescriptor<AlbumEntity>(
//            predicate: #Predicate{$0.from == "travel"},
            sortBy: [
//                SortDescriptor(\.from, order: .forward),
                SortDescriptor(\.photoCount, order: .reverse),
                SortDescriptor(\.displayName, order: .forward)
            ]
        )
        return try context.fetch(fetchDescriptor).map {$0.toDomainWithKey()}
    }

    public func fetchAll(from: String) throws -> [Album] {

        let context = ModelContext(container)

        let fetchDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate{$0.from == from},
            sortBy: [
                SortDescriptor(\.photoCount, order: .reverse),
                SortDescriptor(\.displayName, order: .forward)
            ]
        )
        return try context.fetch(fetchDescriptor).map {$0.toDomainWithKey()}
    }

    public func fetchAlbum(id: UUID) throws -> Album? {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<AlbumEntity>(predicate: #Predicate { $0.id == id })
        return try context.fetch(fetchDescriptor).first?.toDomainWithKey()
    }

    public func fetchAutoAll() throws -> [Album] {

        let context = ModelContext(container)

        let fetchDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.isAuto == true }
        )
        return try context.fetch(fetchDescriptor).map {$0.toDomain()}
    }

    public func fetchPhotos(by albumId: UUID) throws -> [Photo] {

        let context = ModelContext(container)
        // PhotoEntity를 관계 predicate(photo.albums.contains)로 직접 조회하면, 다른 컨텍스트에서 방금
        // 추가한 관계가 앱을 재시작하기 전까진 반영이 안 되는 경우가 있었다(SwiftData의 to-many 관계
        // predicate 관련 알려진 문제). AlbumEntity를 id로 먼저 찾아 album.photos로 읽으면 관계 폴팅이
        // 정상적으로 최신 상태를 반영한다.
        let albumDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.id == albumId }
        )
        guard let album = try context.fetch(albumDescriptor).first else { return [] }

        return album.photos
            .sorted { $0.createdAt > $1.createdAt }
            .map { $0.toDomain() }
    }

    /// 얼굴 앨범 디버깅용: 이 클러스터에 묶인 얼굴들의 사진별 boundingBox (정규화 좌표, Vision 기준 원점 좌하단)
    /// clusterId로 받지만 실제로는 album.name — FaceEmbeddingEntity는 clusterId 문자열이 아니라
    /// cluster(ClusterEntity) 관계로 앨범과 연결되어 있어서 관계를 타고 이름을 비교한다.
    public func fetchFaceBoundingBoxes(clusterId: String) throws -> [String: CGRect] {

        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<FaceEmbeddingEntity>()

        let entities = try context.fetch(fetchDescriptor)

        var result: [String: CGRect] = [:]
        for entity in entities {
            guard entity.cluster?.album?.name == clusterId,
                  let localIdentifier = entity.photo?.localIdentifier else { continue }
            result[localIdentifier] = CGRect(
                x: entity.boundingBoxX,
                y: entity.boundingBoxY,
                width: entity.boundingBoxWidth,
                height: entity.boundingBoxHeight
            )
        }
        return result
    }

    /// 앨범 커버로 쓸 사진(coverPhotoIdentifier) 안에서, 이 앨범 소속 클러스터의 얼굴 boundingBox를 찾는다.
    /// 별도로 저장해두지 않고 커버 사진과 클러스터 관계로 그때그때 찾는 이유는, 저장해두면 커버 사진이
    /// 바뀔 때마다 boundingBox도 같이 갱신해줘야 하는데 그 동기화가 깨지기 쉽기 때문 (실제로 한 번 깨졌었음)
    public func fetchCoverFaceBoundingBox(albumId: UUID) throws -> CGRect? {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<AlbumEntity>(predicate: #Predicate { $0.id == albumId })

        guard let album = try context.fetch(fetchDescriptor).first,
              let coverPhotoIdentifier = album.coverPhotoIdentifier else { return nil }

        for cluster in album.clusters {
            if let entity = cluster.faceEmbeddings.first(where: { $0.photo?.localIdentifier == coverPhotoIdentifier }) {
                return CGRect(
                    x: entity.boundingBoxX,
                    y: entity.boundingBoxY,
                    width: entity.boundingBoxWidth,
                    height: entity.boundingBoxHeight
                )
            }
        }
        return nil
    }

    public func updateAlbum(album: Album) throws {

        let context = ModelContext(container)

        let id = album.id
        let fetchDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.id == id }
        )

        guard let entity = try context.fetch(fetchDescriptor).first else {
            throw AlbumRepositoryError.albumNotFound
        }

        entity.name = album.name
        entity.displayName = album.displayName
        entity.coverPhotoIdentifier = album.coverPhotoIdentifier
        entity.photoCount = album.photoCount

        try context.save()
    }

    public func updateAlbumName(new name: String, id: UUID) throws {

        let context = ModelContext(container)

        let fetchDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.id == id }
        )

        guard let entity = try context.fetch(fetchDescriptor).first else {
            throw AlbumRepositoryError.albumNotFound
        }

        entity.displayName = name
        entity.isRenamed = true

        try context.save()

        try self.syncAlbums()
    }

    public func delete(id: UUID) throws {

        let context = ModelContext(container)

        let fetchDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.id == id }
        )

        guard let entity = try context.fetch(fetchDescriptor).first else {
            throw AlbumRepositoryError.albumNotFound
        }

        context.delete(entity)
        try context.save()

        try self.syncAlbums()
    }

    public func addPhoto(albumId: UUID, photoIdentifier: String) throws {

        let context = ModelContext(container)

        let albumDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.id == albumId }
        )

        let photoDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.localIdentifier == photoIdentifier }
        )

        guard let album = try context.fetch(albumDescriptor).first else {
            throw AlbumRepositoryError.albumNotFound
        }

        guard let photo = try context.fetch(photoDescriptor).first else {
            throw AlbumRepositoryError.photoNotFound
        }

        // 중복 체크
        guard !album.photos.contains(where: { $0.localIdentifier == photoIdentifier }) else { return }

        album.photos.append(photo)

        try context.save()
    }

    public func addPhotos(albumId: UUID, photoIdentifiers: [String]) throws {

        let context = ModelContext(container)

        let albumDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.id == albumId }
        )
        guard let album = try context.fetch(albumDescriptor).first else {
            throw AlbumRepositoryError.albumNotFound
        }

        let ids = photoIdentifiers
        let photoDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { ids.contains($0.localIdentifier) }
        )

        let fetchedPhotos = try context.fetch(photoDescriptor)

        let existingIds = Set(album.photos.map { $0.localIdentifier })
        let uniqueNewPhotos = fetchedPhotos.filter { !existingIds.contains($0.localIdentifier) }

        guard !uniqueNewPhotos.isEmpty else { return }

        album.photos.append(contentsOf: uniqueNewPhotos)
        album.photoCount = album.photos.count

        let newDates = uniqueNewPhotos.map { $0.createdAt }
        if let newMinDate = newDates.min(), let newMaxDate = newDates.max() {
            album.startDate = min(album.startDate ?? newMinDate, newMinDate)
            album.endDate = max(album.endDate ?? newMaxDate, newMaxDate)
        }

//        let allPhotos = album.photos.sorted {$0.createdAt < $1.createdAt}
//        album.startDate = allPhotos.first?.createdAt ?? Date()
//        album.endDate = allPhotos.last?.createdAt ?? Date()
//        
//        album.coverPhotoIdentifier = album.photos.sorted {
//            $0.createdAt > $1.createdAt
//        }.first?.localIdentifier

        let latestNewPhoto = uniqueNewPhotos.max(by: { $0.createdAt < $1.createdAt })
        let currentCoverPhoto = album.photos.first(where: { $0.localIdentifier == album.coverPhotoIdentifier })

        if let latestNew = latestNewPhoto {
            if let currentCover = currentCoverPhoto, currentCover.createdAt >= latestNew.createdAt {
                // 기존 커버가 더 최신이면 유지 (아무것도 안 함)
            } else {
                album.coverPhotoIdentifier = latestNew.localIdentifier
            }
        }

        try context.save()
    }

    public func removePhoto(albumId: UUID, photoIdentifier: String) throws {
//        let fetchDescriptor = FetchDescriptor<AlbumPhotoMapEntity>(
//            predicate: #Predicate {
//                $0.album?.id == albumId &&
//                $0.photo?.localIdentifier == photoIdentifier
//            }
//        )
//        
//        guard let map = try context.fetch(fetchDescriptor).first else { return }
//        context.delete(map)
//        try context.save()
    }

    public func deletePhotos(albumId: UUID, photoIdentifiers: [String]) throws {
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.id == albumId }
        )
        guard let album = try context.fetch(descriptor).first else { return }

        let targets = album.photos.filter { photoIdentifiers.contains($0.localIdentifier) }

        for photo in targets {
            context.delete(photo)
        }

        try context.save()
    }

    public func deleteAutoAlbums(by from: String) throws {

        let context = ModelContext(container)

        let albumDescriptor: FetchDescriptor<AlbumEntity>
        if from == "all" {
            albumDescriptor = FetchDescriptor<AlbumEntity>(
                predicate: #Predicate { $0.isAuto == true }
            )
        } else {
            albumDescriptor = FetchDescriptor<AlbumEntity>(
                predicate: #Predicate { $0.isAuto == true && $0.from == from }
            )
        }

        let autoAlbums = try context.fetch(albumDescriptor)

        autoAlbums.forEach { $0.photos.removeAll() }
        autoAlbums.forEach { context.delete($0) }
        try context.save()
    }

    public func syncPhotoCount() throws {
        let context = ModelContext(container)

        let albumDescriptor = FetchDescriptor<AlbumEntity>()
        let albums = try context.fetch(albumDescriptor)

        albums.forEach { album in
            album.photoCount = album.photos.count
        }

        try context.save()
    }

    public func syncAlbums() throws {
        let updated = try fetchAll()
        albumsSubject.send(updated)
    }

    public func updateLinkedFaceAlbums(albumId: UUID, faceAlbumIds: [UUID]) throws {
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<AlbumEntity>(predicate: #Predicate { $0.id == albumId })
        guard let entity = try context.fetch(descriptor).first else { return }

        entity.linkedFaceAlbumIds = faceAlbumIds
        try context.save()
    }

    public func fetchLinkedFaceAlbums(albumId: UUID) throws -> [Album] {
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<AlbumEntity>(predicate: #Predicate { $0.id == albumId })
        guard let entity = try context.fetch(descriptor).first else { return [] }

        let ids = Set(entity.linkedFaceAlbumIds)
        guard !ids.isEmpty else { return [] }

        let faceAlbums = try context.fetch(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "face" }
        ))
        return faceAlbums.filter { ids.contains($0.id) }.map { $0.toDomainWithKey() }
    }

    public func fetchOtherTravelAlbums(excluding albumId: UUID) throws -> [AlbumMergeCandidate] {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.from == "travel" }
        ))
        let others = albums.filter { $0.id != albumId }

        guard let current = albums.first(where: { $0.id == albumId }),
              let currentStart = current.startDate, let currentEnd = current.endDate
        else {
            return others.map { AlbumMergeCandidate(album: $0.toDomainWithKey(), similarity: -1) }
        }

        // 두 기간이 겹치면 0, 안 겹치면 더 가까운 쪽 경계까지의 간격(초) — 기간이 가까울수록 이어붙일
        // 가능성이 높은 다른 여행이라고 보고 위로 올린다. AlbumMergeCandidate.similarity는 face 쪽의
        // 0~1 유사도 개념이라 여기선 표시용이 아니라 정렬 순서를 매기는 용도로만 음수 간격을 채운다
        func gap(to album: AlbumEntity) -> TimeInterval {
            guard let start = album.startDate, let end = album.endDate else { return .greatestFiniteMagnitude }
            if end < currentStart {
                return currentStart.timeIntervalSince(end)
            } else if start > currentEnd {
                return start.timeIntervalSince(currentEnd)
            } else {
                return 0
            }
        }

        return others
            .sorted { gap(to: $0) < gap(to: $1) }
            .map { AlbumMergeCandidate(album: $0.toDomainWithKey(), similarity: Float(-gap(to: $0))) }
    }

    public func mergeTravelAlbums(
        sourceId: UUID,
        targetId: UUID,
        photoIdentifiers: [String],
        startDate: Date,
        endDate: Date,
        displayName: String,
        linkedFaceAlbumIds: [UUID]
    ) throws {
        let context = ModelContext(container)

        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        guard let source = albums.first(where: { $0.id == sourceId }),
              let target = albums.first(where: { $0.id == targetId }) else { return }

        let photoDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { photoIdentifiers.contains($0.localIdentifier) }
        )
        let photos = try context.fetch(photoDescriptor)

        source.photos = photos
        source.photoCount = photos.count
        source.startDate = startDate
        source.endDate = endDate
        source.displayName = displayName
        source.isRenamed = false
        source.isEdited = true
        source.linkedFaceAlbumIds = linkedFaceAlbumIds
        source.coverPhotoIdentifier = photos.max(by: { $0.createdAt < $1.createdAt })?.localIdentifier

        context.delete(target)
        try context.save()
    }

    public func deleteAll() throws {
        let context = ModelContext(container)

        print("photo-album 연결 제거")
        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        albums.forEach { $0.photos.removeAll() }
        try context.save()

        // AlbumEntity.keywords / .clusters가 .cascade라서, 앨범을 먼저 지우면
        // 아래 둘이 이미 같이 지워져버려 로그가 항상 0개로 찍힌다 — 자식을 먼저 지운다
        try deleteAllLogged(AlbumKeywordEntity.self, context: context)
        try deleteAllLogged(ClusterEntity.self, context: context)

        print("🗑️ AlbumEntity 삭제: \(albums.count)개")
        albums.forEach { context.delete($0) }
        try context.save()

        // PhotoEntity.faceEmbeddings / .labels가 .cascade라서, 사진을 먼저 지우면
        // 아래 둘이 이미 같이 지워져버려 로그가 항상 0개로 찍힌다 — 자식을 먼저 지운다
        try deleteAllLogged(PhotoLabelEntity.self, context: context)
        try deleteAllLogged(FaceEmbeddingEntity.self, context: context)
        try deleteAllLogged(PhotoEntity.self, context: context)

        try deleteAllLogged(ClusterBlacklistEntity.self, context: context)
        try deleteAllLogged(HomeZoneEntity.self, context: context)

        try self.syncAlbums()
    }

    // 타입 단위 배치 삭제(context.delete(model:))는 필수 취급되는 역방향 관계가 있으면
    // "mandatory OTO nullify inverse" 오류로 실패하므로, 개별 fetch 후 하나씩 지운다.
    private func deleteAllLogged<T: PersistentModel>(_ type: T.Type, context: ModelContext) throws {
        let items = try context.fetch(FetchDescriptor<T>())
        items.forEach { context.delete($0) }
        try context.save()
        print("🗑️ \(T.self) 삭제: \(items.count)개")
    }
}
