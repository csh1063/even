//
//  FolderDataRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Combine

public protocol FolderDataRepository {
    
    var foldersPublisher: AnyPublisher<[Folder], Never> {get}
    
    func saveFolder(folder: Folder, returnExist: Bool) throws -> Folder?
    func fetchAll() throws -> [Folder]
    func fetchAutoAll() throws -> [Folder]
    func fetchPhotos(by folderId: UUID) throws -> [Photo]
    func updateFolder(folder: Folder) throws
    func updateFolderName(new name: String, id: UUID) throws
    func delete(id: UUID) throws
    func deleteAutoFolders(by from: String) throws  // 자동 폴더만 삭제
    func addPhoto(folderId: UUID, photoIdentifier: String) throws
    func addPhotos(folderId: UUID, photoIdentifiers: [String]) throws
    func removePhoto(folderId: UUID, photoIdentifier: String) throws
    func syncPhotoCount() throws
    func syncFolders() throws
    func deleteAll() throws
}

extension FolderDataRepository {
    func saveFolder(folder: Folder, returnExist: Bool = false) throws -> Folder? {
        try self.saveFolder(folder: folder, returnExist: returnExist)
    }
    
    func deleteAutoFolders(by from: String = "all") throws {
        try self.deleteAutoFolders(by: from)
    }
}
