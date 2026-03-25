//
//  AutoFolderUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation

public final class AutoFolderUseCase {
    
    private let photoDataRepository: PhotoDataRepository
    private let folderDataRepository: FolderDataRepository
    
    // 폴더 생성 최소 비율
    private let threshold: Double = 0.05
    
    public init(
        photoDataRepository: PhotoDataRepository,
        folderDataRepository: FolderDataRepository
    ) {
        self.photoDataRepository = photoDataRepository
        self.folderDataRepository = folderDataRepository
    }
    
    public func execute() -> AsyncThrowingStream<FolderProgress, Error> {
        AsyncThrowingStream { continuation in
//            Task {
                do {
                    // 사진 불러오기
                    let photos = try photoDataRepository.fetchAll()
                    guard !photos.isEmpty else {
                        continuation.finish()
                        return
                    }
                    let total = Double(photos.count)
                    continuation.yield(FolderProgress(step: .analyzing, ratio: 0))
                    
                    // 각 라벨 수
                    var labelCount: [String: Int] = [:]
                    photos.forEach { photo in
                        photo.labels.forEach { label in
                            labelCount[label.name, default: 0] += 1
                        }
                    }
                    
                    // 기준 이상의 라벨 분류
                    let qualifiedLabels = labelCount
                        .filter { Double($0.value) / total >= threshold }
                        .sorted { $0.value > $1.value }
                    
                    continuation.yield(FolderProgress(step: .creatingFolders, ratio: 0))
                    
                    try folderDataRepository.deleteAutoFolders()
                    
                    // 폴더 생성
                    for (index, (label, _)) in qualifiedLabels.enumerated() {
                        let folder = Folder(
                            name: label,
                            displayName: label,
                            isAuto: true,
                            keywords: [label],
                            photoCount: 0
                        )
                        try folderDataRepository.saveFolder(folder: folder)
                        
                        print("folder name:", folder.displayName)
                        let ratio = Double(index + 1) / Double(qualifiedLabels.count)
                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: ratio))
                    }
                    
                    // 폴더별 사진 분류
                    let folders = try folderDataRepository.fetchAll().filter { $0.isAuto }
                    var classified = 0
                    
                    // 폴더별로 한번에 추가
                    for folder in folders {
                        let matchedIdentifiers = photos
                            .filter { photo in
                                let photoLabelNames = Set(photo.labels.map { $0.name })
                                return folder.keywords.contains { photoLabelNames.contains($0) }
                            }
                            .map { $0.localIdentifier }
                        
                        try folderDataRepository.addPhotos(
                            folderId: folder.id,
                            photoIdentifiers: matchedIdentifiers
                        )
                        classified += 1
                        let ratio = Double(classified) / Double(folders.count)
                        continuation.yield(FolderProgress(step: .classifying, ratio: ratio))
                    }

                    continuation.yield(FolderProgress(step: .completed, ratio: 1.0))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
//        }
    }
}
