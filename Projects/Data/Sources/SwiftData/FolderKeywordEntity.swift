//
//  FolderKeywordEntity.swift
//  Data
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import SwiftData
import Foundation

@Model
public final class FolderKeywordEntity {
    @Attribute(.unique) public var id: UUID
    public var keyword: String
    public var weight: Float             // 키워드 중요도
    
    public var folder: FolderEntity?
    
    public init(
        id: UUID = UUID(),
        keyword: String,
        weight: Float = 1.0,
        folder: FolderEntity? = nil
    ) {
        self.id = id
        self.keyword = keyword
        self.weight = weight
        self.folder = folder
    }
}
