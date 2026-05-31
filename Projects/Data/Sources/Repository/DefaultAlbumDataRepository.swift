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
        let fetchDescriptor = FetchDescriptor<AlbumEntity>(
            predicate: #Predicate { $0.name == name }
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
                SortDescriptor(\.displayName, order: .forward),
            ]
        )
        return try context.fetch(fetchDescriptor).map {$0.toDomainWithKey()}
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
        let photoFetchDescriptor = FetchDescriptor<PhotoEntity>(
            predicate: #Predicate { photo in
                photo.albums.contains { $0.id == albumId }
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let photos = try context.fetch(photoFetchDescriptor)
        return photos.map { $0.toDomain() }
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
        
        let photos = try context.fetch(photoDescriptor)
        
        let existingIds = Set(album.photos.map { $0.localIdentifier })
        let uniqueNewPhotos = photos.filter { !existingIds.contains($0.localIdentifier) }
        
        album.photos.append(contentsOf: uniqueNewPhotos)
        
        let allPhotos = album.photos.sorted {$0.createdAt < $1.createdAt}
        album.startDate = allPhotos.first?.createdAt ?? Date()
        album.endDate = allPhotos.last?.createdAt ?? Date()
        
        album.photoCount = album.photos.count
        album.coverPhotoIdentifier = album.photos.sorted {
            $0.createdAt > $1.createdAt
        }.first?.localIdentifier
        
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
    
    public func deleteAll() throws {
        let context = ModelContext(container)
        
        print("photo-album 연결 제거")
        let albums = try context.fetch(FetchDescriptor<AlbumEntity>())
        albums.forEach { $0.photos.removeAll() }
        try context.save()
        
        albums.forEach { context.delete($0) }
        try context.save()
        
        print("photo 삭제")
        try context.delete(model: PhotoEntity.self)
        try context.save()
        
        print("label embedding 삭제")
        try context.delete(model: PhotoLabelEntity.self)
        try context.delete(model: FaceEmbeddingEntity.self)
        try context.save()
        
        try self.syncAlbums()
    }
}
