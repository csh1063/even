//
//  AlbumEntity.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class AlbumEntity {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var displayName: String
    public var createdAt: Date
    public var startDate: Date = Date()
    public var endDate: Date = Date()
    
    public var isAuto: Bool              // 자동 생성 폴더 여부
    public var coverPhotoIdentifier: String?
    public var photoCount: Int = 0
    public var from: String
    
    public var isEdited: Bool = false
    
    @Relationship(deleteRule: .nullify)
    public var photos: [PhotoEntity] = []
    
    @Relationship(deleteRule: .cascade)
    public var keywords: [AlbumKeywordEntity] = []
    
    public init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        createdAt: Date = Date(),
        startDate: Date = Date(),
        endDate: Date = Date(),
        isAuto: Bool = false,
        coverPhotoIdentifier: String? = nil,
        from: String
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.createdAt = createdAt
        self.startDate = startDate
        self.endDate = endDate
        self.isAuto = isAuto
        self.coverPhotoIdentifier = coverPhotoIdentifier
        self.from = from
    }
}
