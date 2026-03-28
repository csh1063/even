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
    func fetchPhotos(by folderId: UUID) throws -> [Photo]
    func updateFolder(folder: Folder) throws
    func delete(id: UUID) throws
    func deleteAutoFolders() throws  // 자동 폴더만 삭제
    func addPhoto(folderId: UUID, photoIdentifier: String) throws
    func addPhotos(folderId: UUID, photoIdentifiers: [String]) throws
    func removePhoto(folderId: UUID, photoIdentifier: String) throws
}
