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
}

public final class DefaultAlbumDetailUseCase: AlbumDetailUseCase {

    private let repository: AlbumDataRepository
    private let libraryRepository: PhotoLibraryRepository
    private let faceClusterRepository: FaceClusterRepository

    public init(repository: AlbumDataRepository,
                libraryRepository: PhotoLibraryRepository,
                faceClusterRepository: FaceClusterRepository) {
        self.repository = repository
        self.libraryRepository = libraryRepository
        self.faceClusterRepository = faceClusterRepository
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
}
