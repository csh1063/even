//
//  FolderUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/23/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol FolderUseCase {
    func fetchAll() async throws -> [Folder]
    func createDummy() async throws
}

public final class DefaultFolderUseCase: FolderUseCase {
    
    private let folderRepository: FolderDataRepository
    
    public init(folderRepository: FolderDataRepository) {
        self.folderRepository = folderRepository
    }
    
    public func fetchAll() async throws -> [Folder] {
        try self.folderRepository.fetchAll()
    }
    
    public func createDummy() async throws {
        print("usecase create dummy!")
        let folders = [
            Folder(name: "dummy1", displayName: "dummy1", isAuto: true, photoCount: 0),
            Folder(name: "dummy2", displayName: "dummy2", isAuto: true, photoCount: 0),
            Folder(name: "dummy3", displayName: "dummy3", isAuto: true, photoCount: 0),
            Folder(name: "dummy4", displayName: "dummy4", isAuto: true, photoCount: 0),
            Folder(name: "dummy5", displayName: "dummy5", isAuto: true, photoCount: 0)
        ]
    
        for folder in folders {
            try folderRepository.saveFolder(folder: folder)
        }
    }
}
