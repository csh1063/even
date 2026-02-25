//
//  FolderMapper.swift
//  Data
//
//  Created by sanghyeon on 2/25/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension FolderEntity {
    func toDomain() -> Folder {
        return Folder(
            id: id ?? UUID(),
            name: name ?? ""
        )
    }
}
