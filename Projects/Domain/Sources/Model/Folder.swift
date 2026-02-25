//
//  Folder.swift
//  Domain
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public enum FolderType: String {
    case smart
    case user
    case ai
}

public struct Folder {
    
    let id: UUID
    let name: String
    
    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}
