//
//  PhotoLabelEntity.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class PhotoLabelEntity {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var confidence: Float
    
    public var photo: PhotoEntity?
    
    public init(
        id: UUID = UUID(),
        name: String,
        confidence: Float,
        photo: PhotoEntity? = nil
    ) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.photo = photo
    }
}
