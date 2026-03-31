//
//  PhotoLabel.swift
//  Domain
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public class PhotoLabel: Hashable {
    public let name: String
    public let confidence: Float
    
    public init(name: String, confidence: Float) {
        self.name = name
        self.confidence = confidence
    }
    
    public static func == (lhs: PhotoLabel, rhs: PhotoLabel) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
