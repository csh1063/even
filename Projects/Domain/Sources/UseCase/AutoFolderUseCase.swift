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
    private let threshold: Double = 0.1
    
    public init(
        photoDataRepository: PhotoDataRepository,
        folderDataRepository: FolderDataRepository
    ) {
        self.photoDataRepository = photoDataRepository
        self.folderDataRepository = folderDataRepository
    }
    
    public func execute() -> AsyncThrowingStream<FolderProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // 1. 전체 사진 가져오기
                    print("AutoFolderUseCase 1")
                    let photos = try photoDataRepository.fetchAll()
                    guard !photos.isEmpty else {
                        continuation.finish()
                        return
                    }
                    print("AutoFolderUseCase 2")
                    
                    let total = Double(photos.count)
                    
                    // 2. 라벨별 카운트
                    continuation.yield(FolderProgress(step: .analyzing, ratio: 0))
                    
                    print("AutoFolderUseCase 3")
                    var labelCount: [String: Int] = [:]
                    photos.forEach { photo in
                        photo.labels.forEach { label in
                            labelCount[label.name, default: 0] += 1
                        }
                    }
                    print("AutoFolderUseCase 4")
                    
                    // 3. threshold 이상인 라벨만 필터링
                    let qualifiedLabels = labelCount
                        .filter { Double($0.value) / total >= threshold }
                        .sorted { $0.value > $1.value }
                    
                    print("AutoFolderUseCase 5")
                    continuation.yield(FolderProgress(step: .creatingFolders, ratio: 0))
                    
                    // 4. 기존 자동 폴더 삭제
                    try folderDataRepository.deleteAutoFolders()
                    
                    print("AutoFolderUseCase 6")
                    // 5. 폴더 생성
                    for (index, (label, _)) in qualifiedLabels.enumerated() {
                        let folder = Folder(
                            name: label,
                            displayName: label,
                            isAuto: true,
                            keywords: [label]
                        )
                        try folderDataRepository.saveFolder(folder: folder)
                        
                        let ratio = Double(index + 1) / Double(qualifiedLabels.count)
                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: ratio))
                    }
                    
                    print("AutoFolderUseCase 7")
                    // 6. 사진 분류
                    let folders = try folderDataRepository.fetchAll().filter { $0.isAuto }
                    var classified = 0
                    
                    print("AutoFolderUseCase 1")
                    for photo in photos {
                        let photoLabelNames = Set(photo.labels.map { $0.name })
                        
                        print("AutoFolderUseCase in 2")
                        for folder in folders {
                            let matched = folder.keywords.contains { photoLabelNames.contains($0) }
                            print("AutoFolderUseCase in 3")
                            if matched {
                                print("AutoFolderUseCase in 4")
                                try folderDataRepository.addPhoto(
                                    folderId: folder.id,
                                    photoIdentifier: photo.localIdentifier
                                )
                            }
                            print("AutoFolderUseCase in 5")
                        }
                        
                        classified += 1
                        let ratio = Double(classified) / total
                        print("AutoFolderUseCase in 6")
                        continuation.yield(FolderProgress(step: .classifying, ratio: ratio))
                    }
                    
                    print("AutoFolderUseCase 9")
                    continuation.yield(FolderProgress(step: .completed, ratio: 1.0))
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
