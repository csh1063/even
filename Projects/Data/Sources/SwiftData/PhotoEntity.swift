//
//  PhotoEntity.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class PhotoEntity {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var localIdentifier: String
    public var createdAt: Date
    public var analyzedAt: Date?
    
    @Relationship(deleteRule: .cascade)
    public var labels: [PhotoLabelEntity] = []
    
    @Relationship(deleteRule: .nullify)
    public var folders: [FolderEntity] = []
//    @Relationship(deleteRule: .cascade, inverse: \FolderPhotoMapEntity.photo)
//    public var folderMaps: [FolderPhotoMapEntity] = []
    
    public init(
        id: UUID = UUID(),
        localIdentifier: String,
        createdAt: Date = Date(),
        analyzedAt: Date? = nil
    ) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.createdAt = createdAt
        self.analyzedAt = analyzedAt
    }
}
