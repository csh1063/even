//
//  FaceClusterUseCase.swift
//  Domain
//
//  Created by sanghyeon on 6/9/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol FaceClusterUseCase {
    func clusterAndSaveAlbums() async throws
    func matchAndAddNewEmbeddings(embeddingIds: [UUID]) async throws
    func mergeAlbums(sourceId: UUID, targetId: UUID) async throws
    func excludePhoto(photoId: String, fromAlbumId: UUID) async throws
    func deleteAlbum(albumId: UUID) async throws
    func fetchClusters(albumId: UUID) async throws -> [FaceClusterSummary]
    func splitAlbum(albumId: UUID, clusterIds: [UUID]) async throws
    func fetchOtherFaceAlbumsSortedBySimilarity(excluding albumId: UUID) async throws -> [AlbumMergeCandidate]
}

public final class DefaultFaceClusterUseCase: FaceClusterUseCase {
    private let repository: FaceClusterRepository

    public init(repository: FaceClusterRepository) {
        self.repository = repository
    }

    public func clusterAndSaveAlbums() async throws {
        try await repository.clusterAndSaveAlbums()
    }

    public func matchAndAddNewEmbeddings(embeddingIds: [UUID]) async throws {
        try await repository.matchAndAddNewEmbeddings(embeddingIds: embeddingIds)
    }

    public func mergeAlbums(sourceId: UUID, targetId: UUID) async throws {
        try await repository.mergeAlbums(sourceId: sourceId, targetId: targetId)
    }

    public func excludePhoto(photoId: String, fromAlbumId: UUID) async throws {
        try await repository.excludePhoto(photoId: photoId, fromAlbumId: fromAlbumId)
    }

    public func deleteAlbum(albumId: UUID) async throws {
        try await repository.deleteAlbum(albumId: albumId)
    }

    public func fetchClusters(albumId: UUID) async throws -> [FaceClusterSummary] {
        try await repository.fetchClusters(albumId: albumId)
    }

    public func splitAlbum(albumId: UUID, clusterIds: [UUID]) async throws {
        try await repository.splitAlbum(albumId: albumId, clusterIds: clusterIds)
    }

    public func fetchOtherFaceAlbumsSortedBySimilarity(excluding albumId: UUID) async throws -> [AlbumMergeCandidate] {
        try await repository.fetchOtherFaceAlbumsSortedBySimilarity(excluding: albumId)
    }
}
