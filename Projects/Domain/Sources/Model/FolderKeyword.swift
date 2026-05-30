//
//  FolderKeyword.swift
//  Domain
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct FolderKeyword {
    public let keyword: String
    public let weight: Float
    
    public init(keyword: String, weight: Float = 1.0) {
        self.keyword = keyword
        self.weight = weight
    }
}
