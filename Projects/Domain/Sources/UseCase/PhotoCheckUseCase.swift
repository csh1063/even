//
//  PhotoCheckUseCase.swift
//  Domain
//
//  Created by sanghyeon on 4/4/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoCheckUseCase {
    func checkDeletedPhoto() async throws -> AsyncThrowingStream<ProgressState, Error>
    func syncCoverAndCount() async throws -> AsyncThrowingStream<ProgressState, Error>
}

public class DefaultPhotoCheckUseCase: PhotoCheckUseCase {
    
    private let photoLibraryRepository: PhotoLibraryRepository
    private let photoDataRepository: PhotoDataRepository
    private let folderDataRepository: FolderDataRepository
    
    public init(photoLibraryRepository: PhotoLibraryRepository,
                photoDataRepository: PhotoDataRepository,
                folderDataRepository: FolderDataRepository) {
        self.photoLibraryRepository = photoLibraryRepository
        self.photoDataRepository = photoDataRepository
        self.folderDataRepository = folderDataRepository
    }
    
    public func checkDeletedPhoto() async throws -> AsyncThrowingStream<ProgressState, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    
                    let libraryIds = Set(try await photoLibraryRepository.fetchPhotos().photos.map {$0.localIdentifier})
                    let photoCount = try photoDataRepository.fetchPhotoCount()
                    let countPerPage = 1000
                    let maxPage = Double(photoCount) / Double(countPerPage)

                    var page = 0
                    var deletedPhoto: [String] = []
                    while true {
                        let savedPhotos = try photoDataRepository.fetchIds(page: page, pageSize: countPerPage)
                        print("savedPhotos", "page: \(page)", "count:", savedPhotos.count)
                        if savedPhotos.isEmpty { break }
                        
                        deletedPhoto.append(contentsOf: savedPhotos.filter { !libraryIds.contains($0) })
                        
                        page += 1
                        
                        let ratio = Double(page) / maxPage * 0.8
                        continuation.yield(.progress(ratio))
                    }
                    
                    print("deletedPhoto", deletedPhoto.count)
                    
                    for (index, localIdentifier) in deletedPhoto.enumerated() {
                        try photoDataRepository.delete(identifier: localIdentifier)
                        
                        let ratio = Double(index) / Double(deletedPhoto.count) * 0.2 + 0.8
                        continuation.yield(.progress(ratio))
                    }
                    continuation.yield(.progress(1.0))
                    continuation.yield(.completed)
                    continuation.finish()
                } catch {
                    print("error:", error.localizedDescription)
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func syncCoverAndCount() async throws -> AsyncThrowingStream<ProgressState, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let folders = try folderDataRepository.fetchAll()
                    
                    for (index, folder) in folders.enumerated() {
                        let coverPhotoIdentifier = try photoDataRepository.fetchSyncPhotoId(byFolder: folder.id)
                        let photoCount = try photoDataRepository.fetchSyncPhotoCount(byFolder: folder.id)
                        let newFolder = Folder(id: folder.id,
                                               name: folder.name,
                                               displayName: folder.displayName,
                                               coverPhotoIdentifier: coverPhotoIdentifier,
                                               photoCount: photoCount)
                        
                        try folderDataRepository.updateFolder(folder: newFolder)
                        
                        let ratio = Double(index) / Double(folders.count)
                        continuation.yield(.progress(ratio))
                    }
                    
                    continuation.yield(.progress(1.0))
                    continuation.yield(.completed)
                    continuation.finish()
                } catch {
                    print("error:", error.localizedDescription)
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
