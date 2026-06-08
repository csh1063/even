//
//  AutoAlbumUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreLocation
import Foundation

public protocol AutoAlbumUseCase {
    func execute(_ isPhoto: Bool) -> AsyncThrowingStream<ProgressAlbum, Error>
    func createTravelAutoAlbum() -> AsyncThrowingStream<ProgressAlbum, Error>
    func syncPhotoCount() async throws
    func deletePhotos() async throws
    func deleteAutoAlbums() async throws
}

public final class DefaultAutoAlbumUseCase: AutoAlbumUseCase {
    
    private let photoDataRepository: PhotoDataRepository
    private let albumDataRepository: AlbumDataRepository
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
    
    private let administrativeAreaReplacements: [String: String] = [
        "전북특별자치도": "전라북도",
        "강원특별자치도": "강원도",
        "제주특별자치도": "제주도",
        "도쿄도": "도쿄"
    ]

    private let suffixesToRemove = [
        "특별자치시", "특별광역시", "광역시", "특별시", "시"
    ]
    
    private let suffixesForOverseas = [
        "부", "SAR", "특별행정구", "현"
    ]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    public init(
        photoDataRepository: PhotoDataRepository,
        albumDataRepository: AlbumDataRepository,
        photoCategoryRepository: PhotoCategoryRepository,
        userDefaultRepository: UserDefaultRepository,
        travelRepository: TravelDetectionRepository,
        homeZoneRepository: HomeZoneRepository,
        faceClusterRepository: FaceClusterRepository
    ) {
        self.photoDataRepository = photoDataRepository
        self.albumDataRepository = albumDataRepository
        self.photoCategoryRepository = photoCategoryRepository
        self.userDefaultRepository = userDefaultRepository
        self.travelRepository = travelRepository
        self.homeZoneRepository = homeZoneRepository
        self.faceClusterRepository = faceClusterRepository
    }
    
    public func execute(_ isPhoto: Bool) -> AsyncThrowingStream<ProgressAlbum, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let photoCount = try photoDataRepository.fetchPhotoCount()
                    let countPerPage = 300
                    var page = 0
                    
                    let ruleCategories: [String: AlbumRule] = try await photoCategoryRepository.fetchRuleCategories()
                    
                    var albums: [Album] = try albumDataRepository.fetchAutoAll()
                    var albumPhotoMap: [UUID: [String]] = [:]

                    var allPhotosForTravel: [PhotoLocationSnapshot] = []
                    
                    while true {
                        
                        print("start load page: ", page)
                        let photos = try photoDataRepository.fetchAll(page: page, pageSize: countPerPage)
                        print("end load page: ", page)
                        if photos.isEmpty { break }
                        
                        var yearCount: [String: Int] = [:]
                        var addressCount: [String: [String]] = [:]

                        photos.map { ($0.year, $0.address) }.enumerated().forEach { [weak self] (i, item) in
                            
                            let (year, address) = item
                            if let year, isPhoto {
                                yearCount[year, default: 0] += 1
                            }
                            if let address, !isPhoto {
                                if let (key, addressText) = self?.addressKeyValue(address) {
                                    
                                    if !addressText.isEmpty && !addressCount[key, default: []].contains(addressText) {
                                        addressCount[key, default: []].append(addressText)
                                    }
                                }
                            }
                        }
                        print("yearCount: ", yearCount)
                        print("addressCount: ", addressCount)
                        
                        if isPhoto {
                            // MARK: - 라벨로 사진 분류
                            print("라벨로 사진 분류")

                            for (albumName, rule) in ruleCategories {
                                let matchedPhotos = photos.filter { matchesRule($0, rule: rule) }
                                guard !matchedPhotos.isEmpty else { continue }
                                
                                let album = Album(
                                    name: albumName,
                                    displayName: albumName,
                                    isAuto: true,
                                    photoCount: 0,
                                    from: "category"
                                )
                                if let savedAlbum = try albumDataRepository.saveAlbum(album: album) {
                                    albums.append(savedAlbum)
                                }
                            }
                        
                            // MARK: - 년도로 사진 분류
                            print("년도로 사진 분류")
                            for (year, _) in yearCount {
                                let album = Album(
                                    name: year,
                                    displayName: "\(year)",
                                    isAuto: true,
                                    keywords: ["\(year)", "\(year)년"],
                                    photoCount: 0,
                                    from: "date"
                                )
                                if let savedAlbum = try albumDataRepository.saveAlbum(album: album) {
                                    albums.append(savedAlbum)
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
                            for (address, areas) in addressCount {
                                print("address: ", address, ", areas:", areas)
                                let album = Album(
                                    name: address,
                                    displayName: address,
                                    isAuto: true,
                                    keywords: areas,
                                    photoCount: 0,
                                    from: "location"
                                )
                                if let savedAlbum = try albumDataRepository.saveAlbum(album: album) {
                                    albums.append(savedAlbum)
                                }
                            }
                        }
                        
                        //============================================================================
                        
                        // 폴더별로 한번에 추가
                        for album in albums {
                            let matchedIdentifiers: [String]

                            switch album.from {
                            case "category":
                                guard let rule = ruleCategories[album.name] else { continue }
                                matchedIdentifiers = photos
                                    .filter { matchesRule($0, rule: rule) }
                                    .map { $0.localIdentifier }

                            case "date":
                                matchedIdentifiers = photos
                                    .filter { album.keywords.contains($0.year ?? "") }
                                    .map { $0.localIdentifier }

                            case "location":
                                matchedIdentifiers = photos
                                    .filter { [weak self] in
                                        if let address = $0.address, let (_, addressText) = self?.addressKeyValue(address) {
                                            return album.keywords.contains(addressText)
                                        }
                                        return false
                                    }
                                    .map { $0.localIdentifier }
                            default:
                                continue
                            }

                            albumPhotoMap[album.id, default: []].append(contentsOf: matchedIdentifiers)
                        }
                        
                        let ratio = Double(page) / (Double(photoCount) / Double(countPerPage)) * 4.0 / 5.0
                        print("analyzing ratio:", ratio)
                        continuation.yield(ProgressAlbum(step: .analyzing, ratio: ratio))
                        page += 1
                    }
                    
                    for (index, (albumId, photos)) in albumPhotoMap.enumerated() {
                        print("album: \(albumId), addPhoto count:", photos.count)
                        try albumDataRepository.addPhotos(
                            albumId: albumId,
                            photoIdentifiers: photos
                        )
                        
                        let ratio = (Double(index) / Double(albumPhotoMap.count)) * 1.0 / 5.0 + 0.8
                        print("classifying ratio:", ratio)
                        continuation.yield(ProgressAlbum(step: .classifying, ratio: ratio))
                    }
                    
                    // MARK: - 얼굴 클러스터링으로 사람 폴더 생성
                    if isPhoto {
                        print("얼굴 클러스터링 시작")
                        try await faceClusterRepository.clusterAndSaveAlbums()
                    }
                    
                    try albumDataRepository.syncAlbums()
                    
                    if isPhoto {
                        try await userDefaultRepository.saveAnalyzedDate()
                    } else {
                        try await userDefaultRepository.saveLocationAnalyzedDate()
                    }
                    continuation.yield(ProgressAlbum(step: .completed, ratio: 1.0))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func createTravelAutoAlbum() -> AsyncThrowingStream<ProgressAlbum, Error> {
        
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try self.albumDataRepository.deleteAutoAlbums(by: "travel")
                    
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
                        
                        let place = cleanAreaName(cluster.address, isoCode: cluster.isoCountryCode)
                        let albumName = "\(place) · \(self.dateFormatter.string(from: cluster.startDate))"
                        
                        print("clusters \(albumName), start:", cluster.startDate, ", end:", cluster.endDate)
                        
                        let album = Album(
                            name: albumName,
                            displayName: albumName,
                            isAuto: true,
                            coverPhotoIdentifier: cluster.photos.first?.localIdentifier,
                            photoCount: cluster.photos.count,
                            from: "travel"
                        )
                        if let saved = try albumDataRepository.saveAlbum(
                            album: album,
                            returnExist: true
                        ) {
                            let identifiers = cluster.photos.map { $0.localIdentifier }
                            try albumDataRepository.addPhotos(
                                albumId: saved.id,
                                photoIdentifiers: identifiers
                            )
                        }
                    }
                    
                    try albumDataRepository.syncAlbums()
                    
                    continuation.yield(ProgressAlbum(step: .completed, ratio: 1))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
        
    }
    
    public func syncPhotoCount() async throws {
        try albumDataRepository.syncPhotoCount()
    }
    
    public func deletePhotos() async throws {
        try self.albumDataRepository.deleteAll()
        try await userDefaultRepository.resetAnalyzedDate()
    }
    
    public func deleteAutoAlbums() async throws {
        try self.albumDataRepository.deleteAutoAlbums()
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
                return uniqueWeeks >= 3
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
    
    private func matchesRule(_ photo: Photo, rule: AlbumRule) -> Bool {
        let allPhotoTags = Set(photo.labels.map { $0.name })

        // [검증 1] exclude_tags (confidence 무관하게 태그 존재 자체로 제외)
        let excludeSet = Set(rule.excludeTags)
        if !allPhotoTags.isDisjoint(with: excludeSet) { return false }

        let labelNames = Set(photo.labels
            .filter { $0.confidence >= rule.minConfidence }
            .map { $0.name }
        )
        guard !labelNames.isEmpty else { return false }

        // [검증 2] label_filters (confidence 범위 조건)
        if let filters = rule.labelFilters {
            let passed = filters.allSatisfy { filter in
                let score = photo.labels.first { $0.name == filter.name }?.confidence ?? 0.0
                if let min = filter.min, score < min { return false }
                if let max = filter.max, score > max { return false }
                return true
            }
            if !passed { return false }
        }

        // [검증 3] 타입별 매칭
        if rule.type == "AND_OR_COMBINED", let mustHaveList = rule.mustHaveOneOf {
            return !labelNames.isDisjoint(with: Set(mustHaveList))
                && !labelNames.isDisjoint(with: Set(rule.matchTags))
        } else {
            return !labelNames.isDisjoint(with: Set(rule.matchTags))
        }
    }
    
    private func cleanAreaName(_ name: String, isoCode: String) -> String {
        var result = self.administrativeAreaReplacements[name] ?? name
        if isoCode.uppercased() == "KR" {
            for suffix in self.suffixesToRemove {
                if result.hasSuffix(suffix) {
                    result = String(result.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        } else {
            for suffix in self.suffixesForOverseas {
                if result.uppercased().hasSuffix(suffix.uppercased()) {
                    result = String(result.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        return result
    }
    
    private func addressKeyValue(_ address: PhotoLocation) -> (key: String, value: String)? {
        if let country = address.country, !country.isEmpty {
            let isoCode = address.isoCountryCode ?? ""
            let administrativeArea = cleanAreaName(address.administrativeArea ?? "", isoCode: isoCode)
            let locality = cleanAreaName(address.locality ?? "", isoCode: isoCode)
            let subLocality = cleanAreaName(address.subLocality ?? "", isoCode: isoCode)
            let key = "\(cleanAreaName(country, isoCode: isoCode)) \(administrativeArea)".trimmingCharacters(in: .whitespaces)
            
            let addressText: String
            if locality == administrativeArea || locality.hasSuffix("도") {
                addressText = subLocality
            } else {
                addressText = [locality, subLocality]
                    .compactMap { $0 }
                    .reduce(into: [String]()) { result, value in
                        if result.last != value { result.append(value) }
                    }
                    .joined(separator: " ")
            }
            
            return (key, addressText)
        }
        return nil
    }
}
