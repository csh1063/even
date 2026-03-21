//
//  FolderDataRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol FolderDataRepository {
    func saveFolder(folder: Folder) throws
    func fetchAll() throws -> [Folder]
    func updateFolder(folder: Folder) throws
    func delete(id: UUID) throws
    func addPhoto(folderId: UUID, photoIdentifier: String) throws
    func removePhoto(folderId: UUID, photoIdentifier: String) throws
}
