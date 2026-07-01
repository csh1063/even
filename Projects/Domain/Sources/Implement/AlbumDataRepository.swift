//
//  AlbumDataRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Combine

public protocol AlbumDataRepository {

    var albumsPublisher: AnyPublisher<[Album], Never> {get}

    func saveAlbum(album: Album, returnExist: Bool) throws -> Album?
    func fetchAll() throws -> [Album]
    func fetchAll(from: String) throws -> [Album]
    func fetchAutoAll() throws -> [Album]
    func fetchPhotos(by albumId: UUID) throws -> [Photo]
    func updateAlbum(album: Album) throws
    func updateAlbumName(new name: String, id: UUID) throws
    func delete(id: UUID) throws
    func deleteAutoAlbums(by from: String) throws  // 자동 앨범만 삭제
    func addPhoto(albumId: UUID, photoIdentifier: String) throws
    func addPhotos(albumId: UUID, photoIdentifiers: [String]) throws
    func removePhoto(albumId: UUID, photoIdentifier: String) throws
    func deletePhotos(albumId: UUID, photoIdentifiers: [String]) throws
    func syncPhotoCount() throws
    func syncAlbums() throws
    func deleteAll() throws
}

extension AlbumDataRepository {
    func saveAlbum(album: Album, returnExist: Bool = false) throws -> Album? {
        try self.saveAlbum(album: album, returnExist: returnExist)
    }

    func deleteAutoAlbums(by from: String = "all") throws {
        try self.deleteAutoAlbums(by: from)
    }
}
