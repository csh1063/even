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
    func fetchCoverAnimalBoundingBox(albumId: UUID) async throws -> CGRect?
    /// 앨범 타입에 맞는 삭제 경로로 라우팅한다 — 인물/동물은 재분석해도 다시 안 생기도록
    /// 블랙리스트까지 처리하는 전용 삭제를, 그 외 타입은 범용 삭제를 사용한다.
    func deleteAlbum(_ album: Album) async throws
}

public final class DefaultAlbumUseCase: AlbumUseCase {

    private let albumRepository: AlbumDataRepository
    private let faceClusterRepository: FaceClusterRepository
    private let animalClusterRepository: AnimalClusterRepository

    public var albumsPublisher: AnyPublisher<[Album], Never> {
        self.albumRepository.albumsPublisher
    }

    public init(
        albumRepository: AlbumDataRepository,
        faceClusterRepository: FaceClusterRepository,
        animalClusterRepository: AnimalClusterRepository
    ) {
        self.albumRepository = albumRepository
        self.faceClusterRepository = faceClusterRepository
        self.animalClusterRepository = animalClusterRepository
    }

    public func deleteAlbum(_ album: Album) async throws {
        switch album.from {
        case "face":
            try await faceClusterRepository.deleteAlbum(albumId: album.id)
            try albumRepository.syncAlbums()
        case "animal":
            try await animalClusterRepository.deleteAlbum(albumId: album.id)
            try albumRepository.syncAlbums()
        default:
            try albumRepository.delete(id: album.id)
        }
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

    public func fetchCoverAnimalBoundingBox(albumId: UUID) async throws -> CGRect? {
        try self.albumRepository.fetchCoverAnimalBoundingBox(albumId: albumId)
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
