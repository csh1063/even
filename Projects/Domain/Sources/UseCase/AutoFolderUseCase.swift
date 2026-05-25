//
//  AutoFolderUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreLocation
import Foundation

public protocol AutoFolderUseCase {
    func execute(_ isPhoto: Bool) -> AsyncThrowingStream<ProgressFolder, Error>
    func createTravelAutoFolder() -> AsyncThrowingStream<ProgressFolder, Error>
    func syncPhotoCount() async throws
    func deletePhotos() async throws
    func deleteAutoFolders() async throws
}

public final class DefaultAutoFolderUseCase: AutoFolderUseCase {
    
    private let photoDataRepository: PhotoDataRepository
    private let folderDataRepository: FolderDataRepository
    private let photoCategoryRepository: PhotoCategoryRepository
    private let userDefaultRepository: UserDefaultRepository
    private let travelRepository: TravelDetectionRepository
    private let homeZoneRepository: HomeZoneRepository
    private let faceClusterRepository: FaceClusterRepository
    
    private let reanalyzePeriod: TimeInterval = 90 * 24 * 60 * 60  // 3개월
    private let gridSize: Double = 50                               // 10km
    private let maxHomeZones: Int = 5
    
    // 폴더 생성 최소 비율
    private let threshold: Double = 0.05
    
    public init(
        photoDataRepository: PhotoDataRepository,
        folderDataRepository: FolderDataRepository,
        photoCategoryRepository: PhotoCategoryRepository,
        userDefaultRepository: UserDefaultRepository,
        travelRepository: TravelDetectionRepository,
        homeZoneRepository: HomeZoneRepository,
        faceClusterRepository: FaceClusterRepository
    ) {
        self.photoDataRepository = photoDataRepository
        self.folderDataRepository = folderDataRepository
        self.photoCategoryRepository = photoCategoryRepository
        self.userDefaultRepository = userDefaultRepository
        self.travelRepository = travelRepository
        self.homeZoneRepository = homeZoneRepository
        self.faceClusterRepository = faceClusterRepository
    }
    
    public func execute(_ isPhoto: Bool) -> AsyncThrowingStream<ProgressFolder, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let photoCount = try photoDataRepository.fetchPhotoCount()
                    let countPerPage = 300
                    var page = 0
                    
                    let categories: [String: [String]] = try await photoCategoryRepository.fetchCategories()
                    
                    var folders: [Folder] = try folderDataRepository.fetchAutoAll()
                    var folderPhotoMap: [UUID: [String]] = [:]

                    var allPhotosForTravel: [PhotoLocationSnapshot] = []
                    
                    while true {
                        
                        print("start load page: ", page)
                        let photos = try photoDataRepository.fetchAll(page: page, pageSize: countPerPage)
                        print("end load page: ", page)
                        if photos.isEmpty { break }
                        
                        var yearCount: [String: Int] = [:]
                        var addressCount: [String: Int] = [:]
                        photos.map { ($0.year, $0.address) }.enumerated().forEach { (i, item) in
                            
                            let (year, address) = item
                            if let year, isPhoto {
                                yearCount[year, default: 0] += 1
                            }
                            if let address, !isPhoto {
                                if let country = address.country, !country.isEmpty {
                                    addressCount[country, default: 0] += 1
                                }
//                                if let locality = address.locality, !locality.isEmpty {
//                                    addressCount[locality, default: 0] += 1
//                                }
//                                if let ocean = address.ocean, !ocean.isEmpty {
//                                    addressCount[ocean, default: 0] += 1
//                                }
                            }
                        }
                        print("yearCount: ", yearCount)
                        print("addressCount: ", addressCount)
                        
                        if isPhoto {
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
                                    keywords: keywords,
                                    photoCount: 0,
                                    from: "category"
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
                                    photoCount: 0,
                                    from: "date"
                                )
                                if let savedFolder = try folderDataRepository.saveFolder(folder: folder) {
                                    folders.append(savedFolder)
                                }
                            }
                        }
                        
                        if !isPhoto {
                            allPhotosForTravel.append(
                                contentsOf: photos
                                    .filter { $0.latitude != nil && $0.longitude != nil }
                                    .map { PhotoLocationSnapshot(from: $0) })
                            // MARK: - 주소로 사진 분류
                            print("주소로 사진 분류")
                            for (address, _) in addressCount {
                                
                                let folder = Folder(
                                    name: address,
                                    displayName: address,
                                    isAuto: true,
                                    keywords: [address],
                                    photoCount: 0,
                                    from: "location"
                                )
                                if let savedFolder = try folderDataRepository.saveFolder(folder: folder) {
                                    folders.append(savedFolder)
                                }
                            }
                        }
                        
                        //============================================================================
                        
                        // 폴더별로 한번에 추가
                        for folder in folders {
                            let matchedIdentifiers = photos
                                .filter { photo in
                                    if isPhoto {
                                        let photoLabelNames = Set(photo.labels.map { $0.name })
                                        return folder.keywords.contains {
                                            photoLabelNames.contains($0)
                                            || (photo.year != nil && photo.year == $0)
                                        }
                                    } else {
                                        return folder.keywords.contains {
                                            photo.address != nil
                                            && (photo.address?.country == $0
//                                                || photo.address?.locality == $0
//                                                || photo.address?.ocean == $0
                                            )
                                        }
                                    }
                                }
                                .map { $0.localIdentifier }
                            
                            folderPhotoMap[folder.id, default: []].append(contentsOf: matchedIdentifiers)
                        }
                        
                        let ratio = Double(page) / (Double(photoCount) / Double(countPerPage)) * 4.0 / 5.0
                        print("analyzing ratio:", ratio)
                        continuation.yield(ProgressFolder(step: .analyzing, ratio: ratio))
                        page += 1
                    }
                    
                    for (index, (folderId, photos)) in folderPhotoMap.enumerated() {
                        print("folder: \(folderId), addPhoto count:", photos.count)
                        try folderDataRepository.addPhotos(
                            folderId: folderId,
                            photoIdentifiers: photos
                        )
                        
                        let ratio = (Double(index) / Double(folderPhotoMap.count)) * 1.0 / 5.0 + 0.8
                        print("classifying ratio:", ratio)
                        continuation.yield(ProgressFolder(step: .classifying, ratio: ratio))
                    }
                    
//                    // 추후 좀 더 연구해보자
//                    if !isPhoto {
//                        print("여행 앨범 생성")
//                        let clusters = try await travelRepository.detect(from: allPhotosForTravel)
//                        
//                        print("clusters count", clusters.count)
//                        for cluster in clusters {
//                            let folder = Folder(
//                                name: cluster.folderName,
//                                displayName: cluster.folderDisplayName,
//                                isAuto: true,
//                                coverPhotoIdentifier: cluster.photos.first?.localIdentifier,
//                                keywords: [],
//                                photoCount: cluster.photos.count,
//                                from: "travel"
//                            )
//                            if let saved = try folderDataRepository.saveFolder(
//                                folder: folder,
//                                returnExist: true
//                            ) {
//                                let identifiers = cluster.photos.map { $0.localIdentifier }
//                                try folderDataRepository.addPhotos(
//                                    folderId: saved.id,
//                                    photoIdentifiers: identifiers
//                                )
//                            }
//                        }
//                    }
                    
                    
                    // MARK: - 얼굴 클러스터링으로 사람 폴더 생성
                    if isPhoto {
                        print("얼굴 클러스터링 시작")
                        try await faceClusterRepository.clusterAndSaveFolders()
                    }
                    
                    try folderDataRepository.syncFolders()
                    
                    if isPhoto {
                        try await userDefaultRepository.saveAnalyzedDate()
                    } else {
                        try await userDefaultRepository.saveLocationAnalyzedDate()
                    }
                    continuation.yield(ProgressFolder(step: .completed, ratio: 1.0))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func createTravelAutoFolder() -> AsyncThrowingStream<ProgressFolder, Error> {
        
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try self.folderDataRepository.deleteAutoFolders(by: "travel")
                    
                    var allPhotosForTravel: [PhotoLocationSnapshot] = []
                    allPhotosForTravel = try photoDataRepository.fetchHasCoordinators()
                        .map { PhotoLocationSnapshot(from: $0) }
                    
                    try analyze(from: allPhotosForTravel)
                    
                    let homeZones = try fetchHomeZones()
                    for home in homeZones {
                        print("홈존", home.latitude, home.longitude)
                    }
                    
                    print("여행 앨범 생성")
                    let clusters = try await travelRepository.detect(from: allPhotosForTravel, homeZones: homeZones)
//                    let clusters = try await travelRepository.detect(from: allPhotosForTravel)
                    
                    print("clusters count", clusters.count)
                    for cluster in clusters {
                        print("clusters \(cluster.folderDisplayName), start:", cluster.startDate, ", end:", cluster.endDate)
                        let folder = Folder(
                            name: cluster.folderName,
                            displayName: cluster.folderDisplayName,
                            isAuto: true,
                            coverPhotoIdentifier: cluster.photos.first?.localIdentifier,
                            keywords: [],
                            photoCount: cluster.photos.count,
                            from: "travel"
                        )
                        if let saved = try folderDataRepository.saveFolder(
                            folder: folder,
                            returnExist: true
                        ) {
                            let identifiers = cluster.photos.map { $0.localIdentifier }
                            try folderDataRepository.addPhotos(
                                folderId: saved.id,
                                photoIdentifiers: identifiers
                            )
                        }
                    }
                    
                    try folderDataRepository.syncFolders()
                    
                    continuation.yield(ProgressFolder(step: .completed, ratio: 1))
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
    
    public func deletePhotos() async throws {
        try self.folderDataRepository.deleteAll()
        try await userDefaultRepository.resetAnalyzedDate()
    }
    
    public func deleteAutoFolders() async throws {
        try self.folderDataRepository.deleteAutoFolders()
    }
    
    // 홈존 분석 필요 여부 체크 후 실행
    private func analyzeIfNeeded(from photos: [PhotoLocationSnapshot]) throws {
        let existing = try homeZoneRepository.fetchHomeZones()
        if let last = existing.first, Date().timeIntervalSince(last.analyzedAt) < reanalyzePeriod {
            return  // 3개월 이내면 스킵
        }
        try analyze(from: photos)
    }
    
    // 강제 재분석
    private func analyze(from photos: [PhotoLocationSnapshot]) throws {
        let threeMonthsAgo = Date().addingTimeInterval(-reanalyzePeriod)
        let recent = photos.filter { $0.createdAt >= threeMonthsAgo }
        
        guard !recent.isEmpty else { return }
        
        let grid = Dictionary(grouping: recent) { photo -> String in
            let latKey = (photo.latitude * Double(gridSize)).rounded()
            let lngKey = (photo.longitude * Double(gridSize)).rounded()
            return "\(latKey),\(lngKey)"
        }
        
//        let average = Double(recent.count) / Double(grid.count)

        let zones = grid
//            .filter { Double($0.value.count) >= average }
            .filter { $0.value.count >= 5 }
            .filter { _, photos in
                let uniqueWeeks = Set(photos.map {
                    Calendar.current.component(.weekOfYear, from: $0.createdAt)
                }).count
                return uniqueWeeks >= 4
            }
            .sorted { $0.value.count > $1.value.count }
            .prefix(maxHomeZones)
            .compactMap { _, photos -> HomeZone? in
                guard let first = photos.first else { return nil }
                return HomeZone(
                    latitude: first.latitude,
                    longitude: first.longitude,
                    analyzedAt: Date()
                )
            }
        
        try homeZoneRepository.saveHomeZones(zones)
    }
    
    // 홈존 목록 반환 (여행 필터링용)
    private func fetchHomeZones() throws -> [HomeZone] {
        try homeZoneRepository.fetchHomeZones()
    }
//
//    // 특정 좌표가 홈존 반경 내인지 체크
//    private func isHomeZone(latitude: Double, longitude: Double) throws -> Bool {
//        let zones = try homeZoneRepository.fetchHomeZones()
//        let location = CLLocation(latitude: latitude, longitude: longitude)
//        return zones.contains { zone in
//            let zoneLocation = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
//            return location.distance(from: zoneLocation) < homeZoneRadius
//        }
//    }
}
