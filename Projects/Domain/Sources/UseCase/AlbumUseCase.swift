//
//  AlbumUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/23/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import CoreGraphics
import Combine

public protocol AlbumUseCase {
    var albumsPublisher: AnyPublisher<[Album], Never> {get}

    func fetchAll() async throws -> [Album]
    func fetchAll(from: String) async throws -> [Album]
    func createDummy() async throws
    func fetchCoverFaceBoundingBox(albumId: UUID) async throws -> CGRect?
}

public final class DefaultAlbumUseCase: AlbumUseCase {

    private let albumRepository: AlbumDataRepository

    public var albumsPublisher: AnyPublisher<[Album], Never> {
        self.albumRepository.albumsPublisher
    }

    public init(albumRepository: AlbumDataRepository) {
        self.albumRepository = albumRepository
    }

    public func fetchAll() async throws -> [Album] {
        try self.albumRepository.fetchAll()
    }

    public func fetchAll(from: String) async throws -> [Album] {
        try self.albumRepository.fetchAll(from: from)
    }

    public func fetchCoverFaceBoundingBox(albumId: UUID) async throws -> CGRect? {
        try self.albumRepository.fetchCoverFaceBoundingBox(albumId: albumId)
    }

    public func createDummy() async throws {
        print("usecase create dummy!")
        let albums = [
            Album(name: "dummy1", displayName: "dummy1", isAuto: true, photoCount: 0, from: "dummy"),
            Album(name: "dummy2", displayName: "dummy2", isAuto: true, photoCount: 0, from: "dummy"),
            Album(name: "dummy3", displayName: "dummy3", isAuto: true, photoCount: 0, from: "dummy"),
            Album(name: "dummy4", displayName: "dummy4", isAuto: true, photoCount: 0, from: "dummy"),
            Album(name: "dummy5", displayName: "dummy5", isAuto: true, photoCount: 0, from: "dummy")
        ]

        for album in albums {
            _ = try albumRepository.saveAlbum(album: album)
        }
    }
}
