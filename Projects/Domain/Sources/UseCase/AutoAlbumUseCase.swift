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
    func generateAllAlbums() -> AsyncThrowingStream<ProgressAlbum, Error>
    func createDateAlbums() async throws
    func createLocationAlbums() async throws
    func createCategoryAlbums() async throws
    func createFaceAlbums() async throws
    func createTravelAutoAlbum() -> AsyncThrowingStream<ProgressAlbum, Error>
    func createSimilarAlbum() async throws
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
    private let similarRepository: SimilarPhotoClusterRepository

    private let reanalyzePeriod: TimeInterval = 90 * 24 * 60 * 60  // 3개월
    private let gridSize: Double = 50                               // 10km
    private let maxHomeZones: Int = 5

    private let administrativeAreaReplacements: [String: String] = [
        "전북특별자치도": "전라북도",
        "강원특별자치도": "강원도",
        "제주특별자치도": "제주도",
        "제주시": "제주도",
        "서귀포시": "제주도",
        "도쿄도": "도쿄"
    ]

    private let suffixesToRemove = [
        "특별자치시", "특별광역시", "광역시", "특별시", "시"
    ]

    private let suffixesForOverseas = [
        "부", "SAR", "특별행정구", "현"
    ]

    // 날짜/주소/카테고리 분류 시 페이지 단위로 끊어서 처리 (전체를 한 번에 메모리에 올리면 사진이 많을 때 오래 걸림)
    private let classificationPageSize = 300

    public init(
        photoDataRepository: PhotoDataRepository,
        albumDataRepository: AlbumDataRepository,
        photoCategoryRepository: PhotoCategoryRepository,
        userDefaultRepository: UserDefaultRepository,
        travelRepository: TravelDetectionRepository,
        homeZoneRepository: HomeZoneRepository,
        faceClusterRepository: FaceClusterRepository,
        similarRepository: SimilarPhotoClusterRepository
    ) {
        self.photoDataRepository = photoDataRepository
        self.albumDataRepository = albumDataRepository
        self.photoCategoryRepository = photoCategoryRepository
        self.userDefaultRepository = userDefaultRepository
        self.travelRepository = travelRepository
        self.homeZoneRepository = homeZoneRepository
        self.faceClusterRepository = faceClusterRepository
        self.similarRepository = similarRepository
    }

    // MARK: - 통합 파이프라인

    /// 새로 분석된 사진만 대상으로 (날짜+주소+카테고리) → 얼굴 → 여행 → 비슷한사진 순으로 앨범을 갱신한다.
    /// 날짜/주소/카테고리는 아직 분류되지 않은 사진만, 비슷한사진은 시간 윈도우 안에서만 증분 처리한다.
    public func generateAllAlbums() -> AsyncThrowingStream<ProgressAlbum, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let totalSteps = 4.0

                    try await classifyNewPhotosCore()
                    continuation.yield(ProgressAlbum(step: .creatingAlbums, ratio: 1 / totalSteps))

                    try await createFaceAlbumsCore()
                    continuation.yield(ProgressAlbum(step: .creatingAlbums, ratio: 2 / totalSteps))

                    try await createTravelAlbumsCore()
                    continuation.yield(ProgressAlbum(step: .creatingAlbums, ratio: 3 / totalSteps))

                    try await updateSimilarAlbumsIncrementalCore { ratio in
                        continuation.yield(ProgressAlbum(step: .creatingAlbums, ratio: 3 / totalSteps + ratio * (1 / totalSteps)))
                    }
                    continuation.yield(ProgressAlbum(step: .creatingAlbums, ratio: 1.0))

                    try albumDataRepository.syncAlbums()
                    try await userDefaultRepository.saveAnalyzedDate()
                    try await userDefaultRepository.saveLocationAnalyzedDate()

                    continuation.yield(ProgressAlbum(step: .completed, ratio: 1.0))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - 앨범 타입별 단독 재생성 (테스트/개별 재생성용)

    // "앨범 재생성" 버튼용 — 여행/비슷한사진과 동일하게, 해당 타입 앨범을 전부 지우고 나서 다시 만든다.
    // (generateAllAlbums()의 증분 경로는 이 함수들이 아니라 classifyNewPhotosCore/createFaceAlbumsCore를
    // 직접 쓰고 있어서, 여기서 삭제를 추가해도 이어서분석 흐름에는 영향이 없다)
    public func createDateAlbums() async throws {
        try self.albumDataRepository.deleteAutoAlbums(by: "date")
        try createDateAlbumsCore()
        try albumDataRepository.syncAlbums()
    }

    public func createLocationAlbums() async throws {
        try self.albumDataRepository.deleteAutoAlbums(by: "location")
        try createLocationAlbumsCore()
        try albumDataRepository.syncAlbums()
    }

    public func createCategoryAlbums() async throws {
        try self.albumDataRepository.deleteAutoAlbums(by: "category")
        try await createCategoryAlbumsCore()
        try albumDataRepository.syncAlbums()
    }

    public func createFaceAlbums() async throws {
        try self.albumDataRepository.deleteAutoAlbums(by: "face")
        try await createFaceAlbumsCore()
        try albumDataRepository.syncAlbums()
    }

    public func createSimilarAlbum() async throws {
        let allPhotos = try photoDataRepository.fetchPhotos()
        try await createSimilarAlbumsCore(from: allPhotos)
    }

    public func createTravelAutoAlbum() -> AsyncThrowingStream<ProgressAlbum, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await createTravelAlbumsCore()
                    continuation.yield(ProgressAlbum(step: .completed, ratio: 1.0))
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

    // MARK: - 앨범 생성 코어 로직

    // 라벨이 필요 없는 분류(날짜/주소)는 라벨을 실어오지 않는 가벼운 fetchPhotos로 페이지 단위 처리
    private func createDateAlbumsCore() throws {
        var albums = try albumDataRepository.fetchAll(from: "date")
        var albumPhotoMap: [UUID: [String]] = [:]
        var page = 0

        while true {
            let photos = try photoDataRepository.fetchPhotos(page: page, pageSize: classificationPageSize)
            if photos.isEmpty { break }

            let years = Set(photos.compactMap { $0.year })
            for year in years {
                let album = Album(
                    name: year,
                    displayName: "\(year)",
                    isAuto: true,
                    keywords: ["\(year)", "\(year)년"],
                    photoCount: 0,
                    from: "date"
                )
                if let saved = try albumDataRepository.saveAlbum(album: album) {
                    albums.append(saved)
                }
            }

            for album in albums {
                let matchedIdentifiers = photos
                    .filter { album.keywords.contains($0.year ?? "") }
                    .map { $0.localIdentifier }
                albumPhotoMap[album.id, default: []].append(contentsOf: matchedIdentifiers)
            }

            page += 1
        }

        for (albumId, photoIdentifiers) in albumPhotoMap {
            try albumDataRepository.addPhotos(albumId: albumId, photoIdentifiers: photoIdentifiers)
        }
    }

    private func createLocationAlbumsCore() throws {
        var albums = try albumDataRepository.fetchAll(from: "location")
        var albumPhotoMap: [UUID: [String]] = [:]
        var page = 0

        while true {
            let photos = try photoDataRepository.fetchPhotos(page: page, pageSize: classificationPageSize)
            if photos.isEmpty { break }

            var addressCount: [String: [String]] = [:]
            for photo in photos {
                guard let address = photo.address, let (key, addressText) = addressKeyValue(address) else { continue }
                if !addressText.isEmpty && !addressCount[key, default: []].contains(addressText) {
                    addressCount[key, default: []].append(addressText)
                }
            }

            for (address, areas) in addressCount {
                let album = Album(
                    name: address,
                    displayName: address,
                    isAuto: true,
                    keywords: areas,
                    photoCount: 0,
                    from: "location"
                )
                if let saved = try albumDataRepository.saveAlbum(album: album) {
                    albums.append(saved)
                }
            }

            for album in albums {
                let matchedIdentifiers = photos
                    .filter {
                        if let address = $0.address, let (_, addressText) = addressKeyValue(address) {
                            return album.keywords.contains(addressText)
                        }
                        return false
                    }
                    .map { $0.localIdentifier }
                albumPhotoMap[album.id, default: []].append(contentsOf: matchedIdentifiers)
            }

            page += 1
        }

        for (albumId, photoIdentifiers) in albumPhotoMap {
            try albumDataRepository.addPhotos(albumId: albumId, photoIdentifiers: photoIdentifiers)
        }
    }

    // 카테고리는 라벨이 필요해서 fetchAll(라벨 포함)로 페이지 단위 처리
    private func createCategoryAlbumsCore() async throws {
        let ruleCategories: [String: AlbumRule] = try await photoCategoryRepository.fetchRuleCategories()
        var albums = try albumDataRepository.fetchAll(from: "category")
        var albumPhotoMap: [UUID: [String]] = [:]
        var page = 0

        while true {
            let photos = try photoDataRepository.fetchAll(page: page, pageSize: classificationPageSize)
            if photos.isEmpty { break }

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
                if let saved = try albumDataRepository.saveAlbum(album: album) {
                    albums.append(saved)
                }
            }

            for album in albums {
                guard let rule = ruleCategories[album.name] else { continue }
                let matchedIdentifiers = photos
                    .filter { matchesRule($0, rule: rule) }
                    .map { $0.localIdentifier }
                albumPhotoMap[album.id, default: []].append(contentsOf: matchedIdentifiers)
            }

            page += 1
        }

        for (albumId, photoIdentifiers) in albumPhotoMap {
            try albumDataRepository.addPhotos(albumId: albumId, photoIdentifiers: photoIdentifiers)
        }
    }

    // generateAllAlbums()에서만 쓰는 증분 버전 — 아직 date/category/location 분류를 거치지 않은 사진만
    // fetchAlbumUnclassified로 가져와서 세 종류를 한 번에 처리하고, 처리한 사진은 markAlbumsGenerated로 표시한다.
    // (재생성 테스트 버튼용 createDateAlbums 등은 이 메서드를 쓰지 않고 위의 전체 재계산 버전을 그대로 사용한다.)
    private func classifyNewPhotosCore() async throws {
        let ruleCategories: [String: AlbumRule] = try await photoCategoryRepository.fetchRuleCategories()

        var dateAlbums = try albumDataRepository.fetchAll(from: "date")
        var locationAlbums = try albumDataRepository.fetchAll(from: "location")
        var categoryAlbums = try albumDataRepository.fetchAll(from: "category")

        var dateAlbumPhotoMap: [UUID: [String]] = [:]
        var locationAlbumPhotoMap: [UUID: [String]] = [:]
        var categoryAlbumPhotoMap: [UUID: [String]] = [:]

        while true {
            let photos = try photoDataRepository.fetchAlbumUnclassified(limit: classificationPageSize)
            if photos.isEmpty { break }

            // 날짜
            let years = Set(photos.compactMap { $0.year })
            for year in years {
                let album = Album(
                    name: year,
                    displayName: "\(year)",
                    isAuto: true,
                    keywords: ["\(year)", "\(year)년"],
                    photoCount: 0,
                    from: "date"
                )
                if let saved = try albumDataRepository.saveAlbum(album: album) {
                    dateAlbums.append(saved)
                }
            }
            for album in dateAlbums {
                let matched = photos
                    .filter { album.keywords.contains($0.year ?? "") }
                    .map { $0.localIdentifier }
                guard !matched.isEmpty else { continue }
                dateAlbumPhotoMap[album.id, default: []].append(contentsOf: matched)
            }

            // 주소
            var addressCount: [String: [String]] = [:]
            for photo in photos {
                guard let address = photo.address, let (key, addressText) = addressKeyValue(address) else { continue }
                if !addressText.isEmpty && !addressCount[key, default: []].contains(addressText) {
                    addressCount[key, default: []].append(addressText)
                }
            }
            for (address, areas) in addressCount {
                let album = Album(
                    name: address,
                    displayName: address,
                    isAuto: true,
                    keywords: areas,
                    photoCount: 0,
                    from: "location"
                )
                if let saved = try albumDataRepository.saveAlbum(album: album) {
                    locationAlbums.append(saved)
                }
            }
            for album in locationAlbums {
                let matched = photos
                    .filter {
                        if let address = $0.address, let (_, addressText) = addressKeyValue(address) {
                            return album.keywords.contains(addressText)
                        }
                        return false
                    }
                    .map { $0.localIdentifier }
                guard !matched.isEmpty else { continue }
                locationAlbumPhotoMap[album.id, default: []].append(contentsOf: matched)
            }

            // 카테고리
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
                if let saved = try albumDataRepository.saveAlbum(album: album) {
                    categoryAlbums.append(saved)
                }
            }
            for album in categoryAlbums {
                guard let rule = ruleCategories[album.name] else { continue }
                let matched = photos
                    .filter { matchesRule($0, rule: rule) }
                    .map { $0.localIdentifier }
                guard !matched.isEmpty else { continue }
                categoryAlbumPhotoMap[album.id, default: []].append(contentsOf: matched)
            }

            try photoDataRepository.markAlbumsGenerated(identifiers: photos.map { $0.localIdentifier })
        }

        for (albumId, photoIdentifiers) in dateAlbumPhotoMap {
            try albumDataRepository.addPhotos(albumId: albumId, photoIdentifiers: photoIdentifiers)
        }
        for (albumId, photoIdentifiers) in locationAlbumPhotoMap {
            try albumDataRepository.addPhotos(albumId: albumId, photoIdentifiers: photoIdentifiers)
        }
        for (albumId, photoIdentifiers) in categoryAlbumPhotoMap {
            try albumDataRepository.addPhotos(albumId: albumId, photoIdentifiers: photoIdentifiers)
        }
    }

    private func createFaceAlbumsCore() async throws {
        try await faceClusterRepository.clusterAndSaveAlbums()
        try albumDataRepository.syncAlbums()
    }

    private func createTravelAlbumsCore() async throws {
        try self.albumDataRepository.deleteAutoAlbums(by: "travel")

        let allPhotosForTravel = try photoDataRepository.fetchHasCoordinators()
            .map { PhotoLocationSnapshot(from: $0) }

        // 홈존 만들기
        try analyzeIfNeeded(from: allPhotosForTravel)

        let homeZones = try fetchHomeZones()
        print("🏠 이번 여행 판정에 사용되는 홈존 \(homeZones.count)개")
        for zone in homeZones {
            print("   - \(addressDescription(for: zone, in: allPhotosForTravel)) (분석일: \(zone.analyzedAt))")
        }

        let clusters = try await travelRepository.detect(from: allPhotosForTravel, homeZones: homeZones)

        var placeCounts: [String: Int] = [:]

        for cluster in clusters {
            let place = cleanAreaName(cluster.address, isoCode: cluster.isoCountryCode)

            let currentCount = placeCounts[place, default: 0]
            let albumName = "\(place) \(currentCount)"
            placeCounts[place] = currentCount + 1

            let displayName = "\(place) 여행"

            let album = Album(
                name: albumName,
                displayName: displayName,
                isAuto: true,
                coverPhotoIdentifier: cluster.photos.first?.localIdentifier,
                photoCount: cluster.photos.count,
                from: "travel"
            )
            if let saved = try albumDataRepository.saveAlbum(album: album, returnExist: true) {
                let identifiers = cluster.photos.map { $0.localIdentifier }
                try albumDataRepository.addPhotos(albumId: saved.id, photoIdentifiers: identifiers)
            }
        }

        try albumDataRepository.syncAlbums()
    }

    private func createSimilarAlbumsCore(
        from photos: [Photo],
        onProgress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws {
        try self.albumDataRepository.deleteAutoAlbums(by: "similar")
        let similarAlbum = try albumDataRepository.fetchAll(from: "similar")
        try await similarRepository.clusterAndSaveAlbums(photos: photos, existingAlbums: similarAlbum, onProgress: onProgress)
        try albumDataRepository.syncAlbums()
    }

    // generateAllAlbums()에서만 쓰는 증분 버전 — 아직 비교하지 않은 새 사진만 시간 윈도우 기준으로 처리하고,
    // 기존 비슷한사진 앨범은 삭제하지 않는다 (createSimilarAlbum()은 재생성 테스트 버튼용으로 위 전체 재계산 버전을 그대로 씀).
    private func updateSimilarAlbumsIncrementalCore(
        onProgress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws {
        let newPhotos = try photoDataRepository.fetchSimilarUnchecked()
        guard !newPhotos.isEmpty else { return }

        let allPhotos = try photoDataRepository.fetchPhotos()
        try await similarRepository.clusterNewPhotos(newPhotos: newPhotos, allPhotos: allPhotos, onProgress: onProgress)
        try photoDataRepository.markSimilarChecked(identifiers: newPhotos.map { $0.localIdentifier })
    }

    // MARK: - 여행 관련 함수

    // 홈존 분석 필요 여부 체크 후 실행
    private func analyzeIfNeeded(from photos: [PhotoLocationSnapshot]) throws {
        let existing = try homeZoneRepository.fetchHomeZones()
        if let last = existing.first, Date().timeIntervalSince(last.analyzedAt) < reanalyzePeriod {
            print("🏠 홈존 재분석 스킵 (마지막 분석: \(last.analyzedAt), 아직 3개월 안 지남)")
            return
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

        let zones = grid
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

        print("🏠 홈존 분석 결과 → \(zones.count)개")
        for zone in zones {
            print("   - \(addressDescription(for: zone, in: recent))")
        }

        try homeZoneRepository.saveHomeZones(zones)
    }

    // 홈존 위경도 기준으로 가장 가까운 사진의 주소를 찾아 사람이 알아볼 수 있는 문자열로 변환
    private func addressDescription(for zone: HomeZone, in photos: [PhotoLocationSnapshot]) -> String {
        let zoneLocation = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
        guard let nearest = photos
            .filter({ $0.latitude != 0 || $0.longitude != 0 })
            .min(by: {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: zoneLocation)
                < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: zoneLocation)
            })
        else {
            return "주소 확인 불가 (lat: \(zone.latitude), lng: \(zone.longitude))"
        }

        let components = [nearest.country, nearest.administrativeArea, nearest.locality, nearest.subLocality]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, value in
                if !result.contains(value) { result.append(value) }
            }

        return components.isEmpty ? "주소 확인 불가 (lat: \(zone.latitude), lng: \(zone.longitude))" : components.joined(separator: ", ")
    }

    // 홈존 목록 반환 (여행 필터링용)
    private func fetchHomeZones() throws -> [HomeZone] {
        try homeZoneRepository.fetchHomeZones()
    }

    // MARK: - 장소 관련 함수

    private func matchesRule(_ photo: Photo, rule: AlbumRule) -> Bool {
        // 1. 전체 태그 맵 생성 (이름 검색 속도 최적화 및 원본 점수 보존)
        let labelMap = Dictionary(uniqueKeysWithValues: photo.labels.map { ($0.name, $0.confidence) })

        // [검증 1] exclude_tags (최소한의 유의미한 점수 이상일 때만 제외 처리를 하는 것이 안전함, 여기선 0.3 기준)
        let validExcludeTags = photo.labels
            .filter { $0.confidence >= 0.3 } // 노이즈 태그로 인한 억울한 탈락 방지
            .map { $0.name }

        if !Set(validExcludeTags).isDisjoint(with: Set(rule.excludeTags)) {
            return false
        }

        // [검증 2] label_filters (특정 태그의 수치 범위 제한 검사 - minConfidence 제한을 받지 않음)
        if let filters = rule.labelFilters {
            let passed = filters.allSatisfy { filter in
                let score = labelMap[filter.name] ?? 0.0
                if let min = filter.min, score < min { return false }
                if let max = filter.max, score > max { return false }
                return true
            }
            if !passed { return false }
        }

        // [검증 3] 기준 점수(minConfidence) 이상을 기록한 유효 태그들만 추출
        let validLabels = Set(photo.labels
            .filter { $0.confidence >= rule.minConfidence }
            .map { $0.name }
        )

        guard !validLabels.isEmpty else { return false }

        // [검증 4] 타입별 매칭 (AND_OR_COMBINED vs OR)
        if rule.type == "AND_OR_COMBINED", let mustHaveList = rule.mustHaveOneOf {
            return !validLabels.isDisjoint(with: Set(mustHaveList))
                && !validLabels.isDisjoint(with: Set(rule.matchTags))
        } else {
            return !validLabels.isDisjoint(with: Set(rule.matchTags))
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
