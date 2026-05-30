//
//  Folder.swift
//  Domain
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct Folder {
    public let id: UUID
    public let name: String
    public let displayName: String
    public let createdAt: Date
    public var startDate: Date
    public var endDate: Date
    
    public var isAuto: Bool
    public var coverPhotoIdentifier: String?
    public var keywords: [String]
    public var photos: [Photo]
    public var photoCount: Int
    public var from: String
    
    public var isEdited: Bool = false
    
    // 폴더 생성용 변수
    public var targetYear: String?   // "date"일 때
    public var targetAddress: String? // "location"일 때
    
    public init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        createdAt: Date = Date(),
        startDate: Date = Date(),
        endDate: Date = Date(),
        isAuto: Bool = false,
        coverPhotoIdentifier: String? = nil,
        keywords: [String] = [],
        photos: [Photo] = [],
        photoCount: Int,
        from: String,
        targetYear: String? = nil,
        targetAddress: String? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.isAuto = isAuto
        self.coverPhotoIdentifier = coverPhotoIdentifier
        self.keywords = keywords
        self.photos = photos
        self.photoCount = photoCount
        self.from = from
    }
}
