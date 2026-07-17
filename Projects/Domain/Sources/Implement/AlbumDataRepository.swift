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
    /// 병합 등으로 앨범 상세를 열어둔 채로 서버 쪽 상태(기간/이름 등)가 바뀌었을 수 있을 때, 최신 상태로 다시 조회
    func fetchAlbum(id: UUID) throws -> Album?
    func fetchAutoAll() throws -> [Album]
    func fetchPhotos(by albumId: UUID) throws -> [Photo]
    func fetchFaceBoundingBoxes(clusterId: String) throws -> [String: CGRect]
    func fetchCoverFaceBoundingBox(albumId: UUID) throws -> CGRect?
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

    /// 여행 앨범 생성 시점에 사진이 겹치는 얼굴 앨범들을 연결
    func updateLinkedFaceAlbums(albumId: UUID, faceAlbumIds: [UUID]) throws
    /// 연결된 얼굴 앨범들을 현재 상태(이름 변경 여부 포함) 그대로 조회
    func fetchLinkedFaceAlbums(albumId: UUID) throws -> [Album]

    /// 여행 앨범 병합 후보 — 현재 앨범과 기간이 가까운 순으로 정렬 (여행 중간에 위치가 안 잡혀 둘로
    /// 나뉜 경우 등, 이어붙일 다른 여행을 찾기 쉽게)
    func fetchOtherTravelAlbums(excluding albumId: UUID) throws -> [AlbumMergeCandidate]
    /// 여행 앨범 병합 — source를 새로 계산된 값(전체 사진/기간/이름/연결된 얼굴 앨범)으로 갱신하고 target은 삭제.
    /// 이름/기간/연결 얼굴 앨범 재계산은 AlbumDetailUseCase에서 미리 끝내고 결과만 넘겨준다
    func mergeTravelAlbums(
        sourceId: UUID,
        targetId: UUID,
        photoIdentifiers: [String],
        startDate: Date,
        endDate: Date,
        displayName: String,
        linkedFaceAlbumIds: [UUID]
    ) throws
}

extension AlbumDataRepository {
    func saveAlbum(album: Album, returnExist: Bool = false) throws -> Album? {
        try self.saveAlbum(album: album, returnExist: returnExist)
    }

    func deleteAutoAlbums(by from: String = "all") throws {
        try self.deleteAutoAlbums(by: from)
    }
}
