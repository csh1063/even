//
//  AutoFolderUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation

public protocol AutoFolderUseCase {
    func execute() -> AsyncThrowingStream<FolderProgress, Error>
    func syncPhotoCount() async throws
}

public final class DefaultAutoFolderUseCase: AutoFolderUseCase {
    
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
//                    let total = Double(photos.count)
                    continuation.yield(FolderProgress(step: .analyzing, ratio: 0))
                    
                    var yearCount: [String: Int] = [:]
                    photos.compactMap { $0.year }.forEach { year in
                        print("photo year: ", year)
                        yearCount[year, default: 0] += 1
                    }
                    print("yearCount: ", yearCount)
                    
                    var addressCount: [String: Int] = [:]
                    photos.compactMap { $0.address }.forEach { address in
                        print("address: ", address)
                        if let country = address.country, !country.isEmpty { addressCount[country, default: 0] += 1 }
                        if let locality = address.locality, !locality.isEmpty { addressCount[locality, default: 0] += 1 }
                        if let ocean = address.ocean, !ocean.isEmpty { addressCount[ocean, default: 0] += 1 }
                    }
                    print("addressCount: ", yearCount)
                    
                    // MARK: - 라벨로 사진 분류
                    // ==============================================================
//                    // 각 라벨 수
//                    var labelCount: [String: Int] = [:]
//                    photos.forEach { photo in
//                        photo.labels.forEach { label in
//                            labelCount[label.name, default: 0] += 1
//                        }
//                    }
//                    // 기준 이상의 라벨 분류
//                    let qualifiedLabels = labelCount
//                        .filter { Double($0.value) / total >= threshold }
//                        .sorted { $0.value > $1.value }
////                    
//                    continuation.yield(FolderProgress(step: .creatingFolders, ratio: 0))
//                    
//                    try folderDataRepository.deleteAutoFolders()
//                    
//                    // 폴더 생성
//                    for (index, (label, _)) in qualifiedLabels.enumerated() {
//                        let folder = Folder(
//                            name: label,
//                            displayName: label,
//                            isAuto: true,
//                            keywords: [label],
//                            photoCount: 0
//                        )
//                        try folderDataRepository.saveFolder(folder: folder)
//                        
//                        print("folder name:", folder.displayName)
//                        let ratio = Double(index + 1) / Double(qualifiedLabels.count)
//                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: ratio))
//                    }
                    // ==============================================================
                    
                    // ==============================================================
                    continuation.yield(FolderProgress(step: .creatingFolders, ratio: 0))
                    
                    try folderDataRepository.deleteAutoFolders()
                    
                    let categories: [String: [String]] = [
                        "사람": ["people", "person", "face", "portrait", "adult", "child", "people_group", "clothing", "jacket", "footwear", "sandal", "shoes"],
                        "동물": ["animal", "dog", "cat", "canine", "mammal", "pomeranian", "bird", "fish", "insect"],
                        "음식": ["food", "dish", "cuisine", "meal", "spaghetti", "bowl", "plate", "tableware", "utensil", "drink", "beverage"],
                        "풍경": ["landscape", "outdoor", "sky", "land", "nature", "plant", "flower", "tree", "grass", "beach", "mountain", "water"],
                        "문서": ["paper", "book"],
                        "캡처": ["screenshot"],
                        "음악": ["music", "musical_instrument", "drum", "guitar", "piano"],
                    ]
                    let total = categories.count + yearCount.count + addressCount.count
                    var index = 0
                    for (folderName, keywords) in categories {
                        let matchedPhotos = photos.filter { photo in
                            let labelNames = Set(photo.labels
                                .filter { $0.confidence >= 0.6 }
                                .map { $0.name })
                            return keywords.contains { labelNames.contains($0) }
                        }
                        
                        // 매칭된 사진이 있을 때만 폴더 생성
                        guard !matchedPhotos.isEmpty else { continue }
                        
                        let folder = Folder(
                            name: folderName,
                            displayName: folderName,
                            isAuto: true,
                            keywords: keywords, photoCount: 0
                        )
                        try folderDataRepository.saveFolder(folder: folder)
                        
                        print("folder name:", folder.displayName)
                        index = index + 1
                        let ratio = Double(index) / Double(total)
                        print("categories ratio:", ratio)
                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: ratio))
                    }
                    // ==============================================================
                    
                    // MARK: - 년도로 사진 분류
                    for (i, (year, _)) in yearCount.enumerated() {
                        
                        let folder = Folder(
                            name: year,
                            displayName: "\(year)년",
                            isAuto: true,
                            keywords: [year, "\(year)년"],
                            photoCount: 0
                        )
                        try folderDataRepository.saveFolder(folder: folder)
                        
                        index = index + i
                        let ratio = Double(index) / Double(total)
                        print("yearCount ratio:", ratio)
                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: ratio))
                    }
                    
                    // MARK: - 주소로 사진 분류
                    for (i, (address, _)) in addressCount.enumerated() {
                        
                        let folder = Folder(
                            name: address,
                            displayName: address,
                            isAuto: true,
                            keywords: [address],
                            photoCount: 0
                        )
                        try folderDataRepository.saveFolder(folder: folder)
                        
                        index = index + i
                        let ratio = Double(index) / Double(total)
                        print("addressCount ratio:", ratio)
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
                                return folder.keywords.contains {
                                    photoLabelNames.contains($0)
                                    || (photo.year != nil && photo.year == $0)
                                    || (photo.address != nil
                                        && (photo.address?.country == $0
                                        || photo.address?.locality == $0
                                        || photo.address?.ocean == $0))
                                }
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
    
    public func syncPhotoCount() async throws {
        try folderDataRepository.syncPhotoCount()
    }
}
