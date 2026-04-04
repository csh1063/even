//
//  AutoFolderUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation

public protocol AutoFolderUseCase {
    func execute() -> AsyncThrowingStream<ProgressFolder, Error>
    func syncPhotoCount() async throws
}

public final class DefaultAutoFolderUseCase: AutoFolderUseCase {
    
    private let photoDataRepository: PhotoDataRepository
    private let folderDataRepository: FolderDataRepository
    private let photoCategoryRepository: PhotoCategoryRepository
    
    // 폴더 생성 최소 비율
    private let threshold: Double = 0.05
    
    public init(
        photoDataRepository: PhotoDataRepository,
        folderDataRepository: FolderDataRepository,
        photoCategoryRepository: PhotoCategoryRepository
    ) {
        self.photoDataRepository = photoDataRepository
        self.folderDataRepository = folderDataRepository
        self.photoCategoryRepository = photoCategoryRepository
    }
    
    public func execute() -> AsyncThrowingStream<ProgressFolder, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let photoCount = try photoDataRepository.fetchPhotoCount()
                    let countPerPage = 300
                    var page = 0
                    
                    let categories: [String: [String]] = try await photoCategoryRepository.fetchCategories()
                    
                    var folders: [Folder] = try folderDataRepository.fetchAutoAll()
                    var folderPhotoMap: [UUID: [String]] = [:]
                    
                    while true {
                        
                        print("start load page: ", page)
                        let photos = try photoDataRepository.fetchAll(page: page, pageSize: countPerPage)
                        print("end load page: ", page)
                        if photos.isEmpty { break }
                        
                        var yearCount: [String: Int] = [:]
                        var addressCount: [String: Int] = [:]
                        photos.map { ($0.year, $0.address) }.enumerated().forEach { (i, item) in
                            
                            let (year, address) = item
                            if let year {
                                yearCount[year, default: 0] += 1
                            }
                            if let address {
                                if let country = address.country, !country.isEmpty { addressCount[country, default: 0] += 1 }
                                if let locality = address.locality, !locality.isEmpty { addressCount[locality, default: 0] += 1 }
                                if let ocean = address.ocean, !ocean.isEmpty { addressCount[ocean, default: 0] += 1 }
                            }
                        }
                        print("yearCount: ", yearCount)
                        print("addressCount: ", addressCount)
                        
//                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: 0.3))
//                        print("start delete folders")
//                        try folderDataRepository.deleteAutoFolders()
//                        print("end delete folders")
                        
                        // MARK: - 라벨로 사진 분류
                        print("라벨로 사진 분류")
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
                            if let savedFolder = try folderDataRepository.saveFolder(folder: folder) {
                                folders.append(savedFolder)
                            }
                        }
                        
                        // MARK: - 년도로 사진 분류
                        print("년도로 사진 분류")
                        for (year, _) in yearCount {
                            
                            let folder = Folder(
                                name: year,
                                displayName: "\(year)년",
                                isAuto: true,
                                keywords: [year, "\(year)년"],
                                photoCount: 0
                            )
                            if let savedFolder = try folderDataRepository.saveFolder(folder: folder) {
                                folders.append(savedFolder)
                            }
                        }
                        
                        // MARK: - 주소로 사진 분류
                        print("주소로 사진 분류")
                        for (address, _) in addressCount {
                            
                            let folder = Folder(
                                name: address,
                                displayName: address,
                                isAuto: true,
                                keywords: [address],
                                photoCount: 0
                            )
                            if let savedFolder = try folderDataRepository.saveFolder(folder: folder) {
                                folders.append(savedFolder)
                            }
                        }
                        
                        //============================================================================
                        
                        // 폴더별 사진 분류
//                        print("start get folders")
//                        let folders = try folderDataRepository.fetchAutoAll()
//                        print("end get folders")
                        
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
                            
                            folderPhotoMap[folder.id, default: []].append(contentsOf: matchedIdentifiers)
                        }
                        
                        let ratio = Double(page) / Double(photoCount) / Double(countPerPage) * 4 / 5
                        print("analyzing ratio:", ratio)
                        continuation.yield(ProgressFolder(step: .analyzing, ratio: ratio))
                        page += 1
                    }
                    
                    for (index, (folderId, photos)) in folderPhotoMap.enumerated() {
                        try folderDataRepository.addPhotos(
                            folderId: folderId,
                            photoIdentifiers: photos
                        )
                        
                        let ratio = (Double(index) / Double(folderPhotoMap.count)) * 1 / 5 + 0.8
                        print("classifying ratio:", ratio)
                        continuation.yield(ProgressFolder(step: .classifying, ratio: ratio))
                    }
                    
                    continuation.yield(ProgressFolder(step: .completed, ratio: 1.0))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func syncPhotoCount() async throws {
        try folderDataRepository.syncPhotoCount()
    }
//    public func execute() -> AsyncThrowingStream<FolderProgress, Error> {
//        AsyncThrowingStream { continuation in
//            Task {
//                do {
//                    print("start get photos")
//                    let photos = try photoDataRepository.fetchAll()
//                    print("end get photos")
//                    guard !photos.isEmpty else {
//                        continuation.finish()
//                        return
//                    }
//
//                    continuation.yield(FolderProgress(step: .analyzing, ratio: 0))
//                    
//                    var yearCount: [String: Int] = [:]
//                    var addressCount: [String: Int] = [:]
//                    photos.map { ($0.year, $0.address) }.enumerated().forEach { (i, item) in
//                        
//                        let (year, address) = item
//                        if let year {
//                            print("photo year: ", year)
//                            yearCount[year, default: 0] += 1
//                        }
//                        if let address {
//                            print("address: ", address)
//                            if let country = address.country, !country.isEmpty { addressCount[country, default: 0] += 1 }
//                            if let locality = address.locality, !locality.isEmpty { addressCount[locality, default: 0] += 1 }
//                            if let ocean = address.ocean, !ocean.isEmpty { addressCount[ocean, default: 0] += 1 }
//                        }
//                        let ratio = ((Double(i) / Double(photos.count)) / 3)
//                        print("analyzing ratio:", ratio)
//                        continuation.yield(FolderProgress(step: .analyzing, ratio: ratio))
//                    }
//                    print("yearCount: ", yearCount)
//                    print("addressCount: ", addressCount)
//                    
//                    continuation.yield(FolderProgress(step: .creatingFolders, ratio: 0.3))
//                    print("start delete folders")
//                    try folderDataRepository.deleteAutoFolders()
//                    print("end delete folders")
//                    
//                    // MARK: - 라벨로 사진 분류
//                    print("라벨로 사진 분류")
//                    let categories: [String: [String]] = try await photoCategoryRepository.fetchCategories()
////                    [
////                        "음식": [
////                            "food", "coffee", "cake", "dessert", "fruit", "seafood", "meat", "drink",
////                            "rice", "bread", "soup", "salad", "pizza", "sushi", "ramen", "egg"
////                          ],
////                          "여행/풍경": [
////                            "mountain", "ocean", "beach", "sunset_sunrise", "forest", "sky",
////                            "waterfall", "lake", "river", "snow", "island", "desert"
////                          ],
////                          "사람": [
////                            "people", "portrait", "baby", "child", "adult", "crowd"
////                          ],
////                          "동물": [
////                            "dog", "cat", "bird", "rabbit", "animal", "feline", "canine"
////                          ],
////                          "일상/실내": [
////                            "living_room", "bedroom", "kitchen", "desk", "phone", "computer",
////                            "sofa", "book", "table", "bed"
////                          ],
////                          "특별한 날": [
////                            "celebration", "wedding", "graduation", "birthday_cake", "ceremony", "concert"
////                          ],
////                          "운동/스포츠": [
////                            "sport", "golf", "soccer", "swimming", "hiking", "cycling", "skating", "watersport"
////                          ],
////                          "문서/스크린샷": [
////                            "screenshot", "document", "receipt", "ticket", "text", "handwriting"
////                          ],
////                          "탈것": [
////                            "car", "bicycle", "airplane", "boat", "bus", "train", "truck", "van", "suv"
////                          ]
////                    ]
//                    let total = categories.count + yearCount.count + addressCount.count
//                    var index = 0
//                    for (folderName, keywords) in categories {
//                        let matchedPhotos = photos.filter { photo in
//                            let labelNames = Set(photo.labels
//                                .filter { $0.confidence >= 0.6 }
//                                .map { $0.name })
//                            return keywords.contains { labelNames.contains($0) }
//                        }
//                        
//                        // 매칭된 사진이 있을 때만 폴더 생성
//                        guard !matchedPhotos.isEmpty else { continue }
//                        
//                        let folder = Folder(
//                            name: folderName,
//                            displayName: folderName,
//                            isAuto: true,
//                            keywords: keywords, photoCount: 0
//                        )
//                        try folderDataRepository.saveFolder(folder: folder)
//                        
//                        print("folder name:", folder.displayName)
//                        index = index + 1
//                        let ratio = ((Double(index) / Double(total)) / 3) + 0.3
//                        print("categories ratio:", ratio)
//                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: ratio))
//                    }
//
//                    // MARK: - 년도로 사진 분류
//                    print("년도로 사진 분류")
//                    for (i, (year, _)) in yearCount.enumerated() {
//                        
//                        let folder = Folder(
//                            name: year,
//                            displayName: "\(year)년",
//                            isAuto: true,
//                            keywords: [year, "\(year)년"],
//                            photoCount: 0
//                        )
//                        try folderDataRepository.saveFolder(folder: folder)
//                        
//                        let ratio = ((Double(index + i) / Double(total)) / 3) + 0.3
//                        print("yearCount ratio:", ratio)
//                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: ratio))
//                    }
//                    index = index + yearCount.count
//                    
//                    // MARK: - 주소로 사진 분류
//                    print("주소로 사진 분류")
//                    for (i, (address, _)) in addressCount.enumerated() {
//                        
//                        let folder = Folder(
//                            name: address,
//                            displayName: address,
//                            isAuto: true,
//                            keywords: [address],
//                            photoCount: 0
//                        )
//                        try folderDataRepository.saveFolder(folder: folder)
//                        
//                        let ratio = ((Double(index + i) / Double(total)) / 3) + 0.3
//                        print("addressCount ratio:", ratio)
//                        continuation.yield(FolderProgress(step: .creatingFolders, ratio: ratio))
//                    }
//                    
//                    //============================================================================
//                    
//                    // 폴더별 사진 분류
//                    print("start get folders")
//                    let folders = try folderDataRepository.fetchAutoAll()
//                    print("end get folders")
//                    var classified = 0
//                    
//                    // 폴더별로 한번에 추가
//                    for folder in folders {
//                        let matchedIdentifiers = photos
//                            .filter { photo in
//                                let photoLabelNames = Set(photo.labels.map { $0.name })
//                                return folder.keywords.contains {
//                                    photoLabelNames.contains($0)
//                                    || (photo.year != nil && photo.year == $0)
//                                    || (photo.address != nil
//                                        && (photo.address?.country == $0
//                                        || photo.address?.locality == $0
//                                        || photo.address?.ocean == $0))
//                                }
//                            }
//                            .map { $0.localIdentifier }
//                        
//                        try folderDataRepository.addPhotos(
//                            folderId: folder.id,
//                            photoIdentifiers: matchedIdentifiers
//                        )
//                        classified += 1
//                        let ratio = ((Double(classified) / Double(folders.count)) / 3) + 0.6
//                        print("folders ratio:", ratio)
//                        continuation.yield(FolderProgress(step: .classifying, ratio: ratio))
//                    }
//
//                    continuation.yield(FolderProgress(step: .completed, ratio: 1.0))
//                    continuation.finish()
//                } catch {
//                    continuation.finish(throwing: error)
//                }
//            }
//        }
//    }
}
