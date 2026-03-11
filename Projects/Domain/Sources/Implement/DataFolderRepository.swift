//
//  DataFolderRepository.swift
//  Domain
//
//  Created by sanghyeon on 2/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol DataFolderRepository {
    func create(name: String) async throws -> Folder
    func fetchAll() async throws -> [Folder]
    func fetchPage(offset: Int, limit: Int) async throws -> [Folder]
    func fetch(id: UUID) async throws -> Folder?
    func update(id: UUID, name: String) async throws
    func delete(folderID: UUID) async throws
}
