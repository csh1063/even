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
    public var isAuto: Bool
    public var coverPhotoIdentifier: String?
    public var keywords: [String]
    public var photos: [Photo]
    public var photoCount: Int
    public var from: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        createdAt: Date = Date(),
        isAuto: Bool = false,
        coverPhotoIdentifier: String? = nil,
        keywords: [String] = [],
        photos: [Photo] = [],
        photoCount: Int,
        from: String
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.createdAt = createdAt
        self.isAuto = isAuto
        self.coverPhotoIdentifier = coverPhotoIdentifier
        self.keywords = keywords
        self.photos = photos
        self.photoCount = photoCount
        self.from = from
    }
}
