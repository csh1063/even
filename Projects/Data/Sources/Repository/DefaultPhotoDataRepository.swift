//
//  DefaultPhotoDataRepository.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation
import Domain

public final class DefaultPhotoDataRepository: PhotoDataRepository {

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func savePhoto(photo: Photo) throws {
        let context = ModelContext(container)
        let identifier = photo.localIdentifier
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.localIdentifier == identifier }
        )

        let existing = try context.fetch(fetchDescriptor)
        guard existing.isEmpty else { return }

        let entity = PhotoEntity(
            id: photo.id,
            localIdentifier: photo.localIdentifier,
            createdAt: photo.createdAt,
            latitude: photo.latitude,
            longitude: photo.longitude,
            isoCountryCode: photo.isoCountryCode,
            address: photo.address,
            addressEn: photo.addressEn,
            year: photo.year,
            month: photo.month
        )
        context.insert(entity)
        try context.save()
    }

    // 라이브러리 전체를 분석 전에 한 번에 저장할 때 사용 — 사진마다 context/save를 새로 만들지 않고
    // 기존 id를 한 번에 조회한 뒤 하나의 context에 모아 insert, 일정 개수마다만 save 커밋한다.
    public func saveAllPhotosBase(_ photos: [Photo]) throws {
        guard !photos.isEmpty else { return }

        let context = ModelContext(container)
        let existingIds = Set(try context.fetch(FetchDescriptor<PhotoEntity>()).map { $0.localIdentifier })

        let batchSize = 500
        var pendingCount = 0

        for photo in photos where !existingIds.contains(photo.localIdentifier) {
            let entity = PhotoEntity(
                id: photo.id,
                localIdentifier: photo.localIdentifier,
                createdAt: photo.createdAt,
                latitude: photo.latitude,
                longitude: photo.longitude,
                isoCountryCode: photo.isoCountryCode,
                address: photo.address,
                addressEn: photo.addressEn,
                year: photo.year,
                month: photo.month
            )
            context.insert(entity)
            pendingCount += 1

            if pendingCount >= batchSize {
                try context.save()
                pendingCount = 0
            }
        }

        if pendingCount > 0 {
            try context.save()
        }
    }

    public func saveAndUpdateLabels(photo: Photo, labels: [PhotoLabel]) async throws {
        try await Task.detached(priority: .high) { [container] in
            let context = ModelContext(container)

            let identifier = photo.localIdentifier
            let fetchDescriptor = FetchDescriptor<PhotoEntity>(
                predicate: #Predicate { $0.localIdentifier == identifier }
            )

            let entity: PhotoEntity
            if let existing = try context.fetch(fetchDescriptor).first {
                entity = existing

                if let latitude = photo.latitude { entity.latitude = latitude }
                if let longitude = photo.longitude { entity.longitude = longitude }
                if let isoCountryCode = photo.isoCountryCode { entity.isoCountryCode = isoCountryCode }
                if let address = photo.address { entity.address = address }
                if let addressEn = photo.addressEn { entity.addressEn = addressEn }
                if let year = photo.year { entity.year = year }
                if let month = photo.month { entity.month = month }
            } else {
                entity = PhotoEntity(
                    id: photo.id,
                    localIdentifier: photo.localIdentifier,
                    createdAt: photo.createdAt,
                    latitude: photo.latitude,
                    longitude: photo.longitude,
                    isoCountryCode: photo.isoCountryCode,
                    address: photo.address,
                    addressEn: photo.addressEn,
                    year: photo.year,
                    month: photo.month
                )
                context.insert(entity)
            }

            if !labels.isEmpty {
                entity.labels.forEach { context.delete($0) }

                labels.forEach {
                    let labelEntity = PhotoLabelEntity(
                        name: $0.name,
                        confidence: $0.confidence,
                        photo: entity
                    )
                    context.insert(labelEntity)
                }
            }

            let faceEmbeddings = photo.faceEmbedding
            if !photo.faceEmbedding.isEmpty {

                entity.faceEmbeddings.forEach { context.delete($0) }

                faceEmbeddings.forEach {
                    let labelEntity = FaceEmbeddingEntity.from(
                        domain: $0,
                        photo: entity
                    )
                    context.insert(labelEntity)
                }
            }

            entity.analyzedAt = Date()
            try context.save()
        }.value
    }

    public func fetchPhotos(page: Int = -1, pageSize: Int = 300) throws -> [Photo] {
        let context = ModelContext(container)
        var fetchDescriptor = FetchDescriptor<PhotoEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if page >= 0 {
            fetchDescriptor.fetchLimit = pageSize
            fetchDescriptor.fetchOffset = page * pageSize
        }

        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }

    public func fetchAll(page: Int = -1, pageSize: Int = 50) throws -> [Photo] {

        let context = ModelContext(container)

        var fetchDescriptor = FetchDescriptor<PhotoEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if page >= 0 {
            fetchDescriptor.fetchLimit = pageSize
            fetchDescriptor.fetchOffset = page * pageSize
        }

        return try context.fetch(fetchDescriptor).map { $0.toDomainAll() }
    }

    public func fetchPhotoCount() throws -> Int {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>()
        return try context.fetchCount(fetchDescriptor)
    }

    public func fetchIds(page: Int, pageSize: Int) throws -> [String] {

        let context = ModelContext(container)

        var fetchDescriptor = FetchDescriptor<PhotoEntity>()

        if page >= 0 {
            fetchDescriptor.fetchLimit = pageSize
            fetchDescriptor.fetchOffset = page * pageSize
        }

        return try context.fetch(fetchDescriptor).map {$0.localIdentifier}
    }

    public func fetchAnalyzed() throws -> [String] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.analyzedAt != nil }
        )
        return try context.fetch(fetchDescriptor).map { $0.localIdentifier }
    }

    public func fetchHasCoordinators() throws -> [Photo] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.longitude != nil && $0.latitude != nil }
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }

    public func fetchLocationUnanalyzed() throws -> [Photo] {
        let context = ModelContext(container)
        // 라벨/얼굴 분석(analyzedAt)과 주소 변환이 이제 동시에 진행되므로, 라벨 분석 완료 여부가 아니라
        // 기본 정보 저장 단계(saveAllPhotosBase)에서 채워지는 latitude 유무로 대상 사진을 판단한다.
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.latitude != nil && $0.isoCountryCode == nil }
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }

    public func fetchSyncPhotoId(byAlbum localIdentifier: UUID) throws -> String? {
        let context = ModelContext(container)
        var fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate<PhotoEntity> {
                $0.albums.contains { $0.id == localIdentifier }
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = 1

        guard let entity = try context.fetch(fetchDescriptor).first else {
            return nil
        }

        return entity.localIdentifier
    }

    public func fetchSyncPhotoCount(byAlbum localIdentifier: UUID) throws -> Int {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate<PhotoEntity> {
                $0.albums.contains { $0.id == localIdentifier }
            }
        )
        return try context.fetchCount(fetchDescriptor)
    }

    public func fetchUnanalyzed() throws -> [Photo] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.analyzedAt == nil }
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }

    // 날짜/주소/카테고리 앨범 분류를 아직 거치지 않은 사진만 limit개씩 반환.
    // 반환된 사진은 markAlbumsGenerated로 표시해야 다음 호출에서 다시 나오지 않는다 (offset이 아니라 항상 "맨 앞 남은 것"을 가져옴).
    public func fetchAlbumUnclassified(limit: Int) throws -> [Photo] {
        let context = ModelContext(container)
        var fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.albumsGeneratedAt == nil }
        )
        fetchDescriptor.fetchLimit = limit
        return try context.fetch(fetchDescriptor).map { $0.toDomainAll() }
    }

    public func markAlbumsGenerated(identifiers: [String]) throws {
        guard !identifiers.isEmpty else { return }
        let context = ModelContext(container)
        let idSet = Set(identifiers)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { idSet.contains($0.localIdentifier) }
        )
        let now = Date()
        for entity in try context.fetch(fetchDescriptor) {
            entity.albumsGeneratedAt = now
        }
        try context.save()
    }

    // 비슷한사진 비교를 아직 거치지 않은 "새 사진" 전체 (시간 윈도우 이웃을 찾으려면 전체 목록이 필요해서 페이지네이션하지 않음)
    public func fetchSimilarUnchecked() throws -> [Photo] {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.similarCheckedAt == nil }
        )
        return try context.fetch(fetchDescriptor).map { $0.toDomain() }
    }

    public func markSimilarChecked(identifiers: [String]) throws {
        guard !identifiers.isEmpty else { return }
        let context = ModelContext(container)
        let idSet = Set(identifiers)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { idSet.contains($0.localIdentifier) }
        )
        let now = Date()
        for entity in try context.fetch(fetchDescriptor) {
            entity.similarCheckedAt = now
        }
        try context.save()
    }

    public func delete(identifier: String) throws {
        let context = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { $0.localIdentifier == identifier }
        )

        guard let entity = try context.fetch(fetchDescriptor).first else {
            throw PhotoRepositoryError.photoNotFound
        }

        for album in entity.albums where album.coverPhotoIdentifier == identifier {
            let photos = album.photos
                .filter { $0.localIdentifier != identifier }
                .sorted { $0.createdAt > $1.createdAt }
            album.coverPhotoIdentifier = photos.first?.localIdentifier

            for album in entity.albums {
                album.photoCount = photos.count
            }
        }

        context.delete(entity)

        try context.save()
    }
}
