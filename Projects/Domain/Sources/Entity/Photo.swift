//
//  Photo.swift
//  Domain
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

//public struct Photo: Identifiable {
//    public let id: UUID
//    public let assetIdentifier: String
//    public let tags: [Tag]
//
//    public init(
//        id: UUID,
//        assetIdentifier: String,
//        tags: [Tag]
//    ) {
//        self.id = id
//        self.assetIdentifier = assetIdentifier
//        self.tags = tags
//    }
//}
//@Model
public class Photo {
    public var id: UUID
    public var localIdentifier: String
    public var createdAt: Date
    
    public init(localIdentifier: String) {
        self.id = UUID()
        self.localIdentifier = localIdentifier
        self.createdAt = Date()
    }
}
