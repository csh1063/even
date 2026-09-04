//
//  Album.swift
//  Domain
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct Album {
    public let id: UUID
    public let name: String
    public var displayName: String
    public let createdAt: Date
    public var startDate: Date?
    public var endDate: Date?

    public var isAuto: Bool
    public var coverPhotoIdentifier: String?
    /// 사용자가 "대표 사진 변경"으로 직접 고른 적 있는지 — true면 분석/동기화 중 자동으로 다시
    /// 계산되는 커버(최신 사진, 얼굴 화질 베스트 등)가 이 선택을 덮어쓰지 않는다
    public var coverPhotoManuallySet: Bool
    public var keywords: [String]
    public var photos: [Photo]
    public var photoCount: Int
    public var from: String
    public var isEdited: Bool = false        // 병합/제외/분리 등 구조가 변경된 적 있는지
    public var isRenamed: Bool = false       // 사용자가 이름을 직접 바꾼 적 있는지

    public var clusterId: [String] = []

    public init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        createdAt: Date = Date(),
        startDate: Date? = nil,
        endDate: Date? = nil,
        isAuto: Bool = false,
        coverPhotoIdentifier: String? = nil,
        coverPhotoManuallySet: Bool = false,
        keywords: [String] = [],
        photos: [Photo] = [],
        photoCount: Int,
        from: String,
        isEdited: Bool = false,
        isRenamed: Bool = false,
        clusterId: [String] = []
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.isAuto = isAuto
        self.coverPhotoIdentifier = coverPhotoIdentifier
        self.coverPhotoManuallySet = coverPhotoManuallySet
        self.keywords = keywords
        self.photos = photos
        self.photoCount = photoCount
        self.from = from
        self.isEdited = isEdited
        self.isRenamed = isRenamed
        self.clusterId = clusterId
    }
}
