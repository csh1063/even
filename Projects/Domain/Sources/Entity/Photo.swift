//
//  Photo.swift
//  Domain
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct Photo {
    public let id: UUID
    public let localIdentifier: String
    public let createdAt: Date
    public var analyzedAt: Date?
    public var labels: [PhotoLabel]
    
    public init(
        id: UUID = UUID(),
        localIdentifier: String,
        createdAt: Date = Date(),
        analyzedAt: Date? = nil,
        labels: [PhotoLabel] = []
    ) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.createdAt = createdAt
        self.analyzedAt = analyzedAt
        self.labels = labels
    }
}
