//
//  FolderEntity.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class FolderEntity {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var displayName: String
    public var createdAt: Date
    public var isAuto: Bool              // 자동 생성 폴더 여부
    public var coverPhotoIdentifier: String?
    public var photoCount: Int = 0
    public var from: String
    
    @Relationship(deleteRule: .nullify)
    public var photos: [PhotoEntity] = []
    
    @Relationship(deleteRule: .cascade)
    public var keywords: [FolderKeywordEntity] = []
    
    public init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        createdAt: Date = Date(),
        isAuto: Bool = false,
        coverPhotoIdentifier: String? = nil,
        from: String
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.createdAt = createdAt
        self.isAuto = isAuto
        self.coverPhotoIdentifier = coverPhotoIdentifier
        self.from = from
    }
}
