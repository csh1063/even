//
//  AnimalClusterBlacklistEntity.swift
//  Data
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class AnimalClusterBlacklistEntity {
    @Attribute(.unique) public var id: UUID
    public var embeddingIds: [UUID]
    public var createdAt: Date = Date()

    public init(id: UUID = UUID(), embeddingIds: [UUID]) {
        self.id = id
        self.embeddingIds = embeddingIds
    }
}
