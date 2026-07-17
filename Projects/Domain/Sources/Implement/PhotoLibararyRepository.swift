//
//  PhotoLibraryRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoLibraryRepository {
    func fetchPhotos(page: Int, pageCount: Int) async throws -> PhotoList
    func fetchPhotoCount() async throws -> Int
    func fetchPhotoIds() async throws -> [String]
    func checkPermission() async throws -> PhotoPermission
    func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T>
    func deletePhotos(by ids: [String]) async throws
    /// 여행 앨범 "사진 추가" 피커용 — 기준 날짜 이전 사진(최신순)/이후 사진(오래된순)을 페이지 단위로 조회
    func fetchPhotos(before date: Date, page: Int, pageCount: Int) async throws -> PhotoList
    func fetchPhotos(after date: Date, page: Int, pageCount: Int) async throws -> PhotoList
}

extension PhotoLibraryRepository {
    func fetchPhotos(page: Int = -1, pageCount: Int = 300) async throws -> PhotoList {
        try await fetchPhotos(page: page, pageCount: pageCount)
    }
}
