//
//  ClusterBlacklistEntity.swift
//  Data
//
//  Created by sanghyeon on 6/9/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class ClusterBlacklistEntity {
    @Attribute(.unique) public var id: UUID
    public var embeddingIds: [UUID]
    public var createdAt: Date = Date()

    public init(id: UUID = UUID(), embeddingIds: [UUID]) {
        self.id = id
        self.embeddingIds = embeddingIds
    }
}
