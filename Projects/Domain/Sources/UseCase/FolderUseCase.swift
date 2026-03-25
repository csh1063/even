//
//  FolderUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/23/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public final class FolderUseCase {
    
    private let folderRepository: FolderDataRepository
    
    public init(folderRepository: FolderDataRepository) {
        self.folderRepository = folderRepository
    }
    
    public func fetchAll() async throws -> [Folder] {
        try self.folderRepository.fetchAll()
    }
}
