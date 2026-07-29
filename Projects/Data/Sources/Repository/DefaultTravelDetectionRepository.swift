//
//  TravelDetectionService.swift
//  Data
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import Foundation
import CoreLocation

public final class DefaultTravelDetectionRepository: TravelDetectionRepository {

    private let timeGapThreshold: TimeInterval = 2 * 24 * 60 * 60
    private let moveDistanceThreshold: Double = 50_000
    private let stayDistanceThreshold: Double = 20_000
    private let minimumClusterSize: Int = 10
    private let localityDominanceThreshold: Double = 0.7
    private let geocodingSampleGridSize: Double = 100  // 1km = 0.01도 → 100 = 1/100 = 0.01
    private let homeZoneRadius: Double = 20_000

    private let geocoderService: GeocoderService

    public init(geocoderService: GeocoderService) {
        self.geocoderService = geocoderService
    }

    public func detect(from photos: [PhotoLocationSnapshot], homeZones: [HomeZone]) async throws -> [TravelCluster] {
        let located = photos
            .filter { $0.latitude != 0 || $0.longitude != 0 }
            .sorted { $0.createdAt < $1.createdAt }
            .map { ($0, CLLocation(latitude: $0.latitude, longitude: $0.longitude)) }

        guard !located.isEmpty else { return [] }

        var rawClusters: [[(PhotoLocationSnapshot, CLLocation)]] = []
        var current: [(PhotoLocationSnapshot, CLLocation)] = [located[0]]

        for i in 1..<located.count {
            let (prevSnapshot, prevLocation) = located[i - 1]
            let (currSnapshot, currLocation) = located[i]

            if homeZoneIndex(currSnapshot, homeZones: homeZones) != nil {
                rawClusters.append(current)
                current = []
                continue
            }

            // prev가 홈존이었으면 gap/distance 계산 스킵하고 그냥 추가
            if homeZoneIndex(prevSnapshot, homeZones: homeZones) != nil {
//                current.append(located[i])
                current = [located[i]]
                continue
            }

            let gap = currSnapshot.createdAt.timeIntervalSince(prevSnapshot.createdAt)
            let distance = currLocation.distance(from: prevLocation)
            let isNormalStepping = gap < timeGapThreshold && distance < moveDistanceThreshold

            if isNormalStepping {
                current.append(located[i])
            } else {
                rawClusters.append(current)
                current = [located[i]]
            }
        }

        rawClusters.append(current)

        let filteredClusters = rawClusters.filter { $0.count >= minimumClusterSize }

        var initialClusters: [TravelCluster] = []
        for raw in filteredClusters {
            let snapshots = raw.map { $0.0 }
            if let cluster = try await buildCluster(from: snapshots) {
                initialClusters.append(cluster)
            }
        }
        // ⭐️ [여기서 합치기] 주소와 날짜가 겹치거나 이어지는 앨범 병합 로직 ⭐️
        guard !initialClusters.isEmpty else { return [] }

        var mergedClusters: [TravelCluster] = []
        // 날짜 순서대로 정렬되어 있다고 보장되지만 확정성을 위해 재정렬
        let sortedClusters = initialClusters.sorted { $0.startDate < $1.startDate }

        var currentCluster = sortedClusters[0]

        for nextCluster in sortedClusters.dropFirst() {
            // 같은 도(administrativeArea) 이거나 같은 시/군/구(locality)인지 체크 (둘 다 비어있지 않아야 함)
            let isSameRegion = (!(currentCluster.locality ?? "").isEmpty && currentCluster.locality == nextCluster.locality) ||
            (!currentCluster.administrativeArea.isEmpty && currentCluster.administrativeArea == nextCluster.administrativeArea)

            // 두 여행 사이의 시간 간격이 2일(timeGapThreshold) 이하로 연속되는지 체크
            let isTimeConnected = nextCluster.startDate.timeIntervalSince(currentCluster.endDate) <= timeGapThreshold

            if isSameRegion && isTimeConnected {
                // 하나로 합치기: 사진 배열을 합치고 날짜 범위를 업데이트
                let combinedPhotos = (currentCluster.photos + nextCluster.photos).sorted { $0.createdAt < $1.createdAt }

                // 두 클러스터의 주소 데이터 병합 처리 (더 빈도가 높거나 대표성 있는 값 유지)
                currentCluster = TravelCluster(
                    photos: combinedPhotos,
                    country: currentCluster.country.isEmpty ? nextCluster.country : currentCluster.country,
                    administrativeArea: currentCluster.administrativeArea.isEmpty ? nextCluster.administrativeArea : currentCluster.administrativeArea,
                    locality: (currentCluster.locality ?? "").isEmpty ? nextCluster.locality : currentCluster.locality,
                    subLocality: (currentCluster.subLocality ?? "").isEmpty ? nextCluster.subLocality : currentCluster.subLocality,
                    isoCountryCode: currentCluster.isoCountryCode.isEmpty ? nextCluster.isoCountryCode : currentCluster.isoCountryCode,
                    startDate: min(currentCluster.startDate, nextCluster.startDate),
                    endDate: max(currentCluster.endDate, nextCluster.endDate)
                )
            } else {
                // 조건이 안 맞으면 지금까지 모은 걸 저장하고 새 기준으로 전환
                mergedClusters.append(currentCluster)
                currentCluster = nextCluster
            }
        }
        mergedClusters.append(currentCluster) // 마지막 남은 앨범 추가

        return mergedClusters
//        return result
    }

    private func homeZoneIndex(_ photo: PhotoLocationSnapshot, homeZones: [HomeZone]) -> Int? {
        let location = CLLocation(latitude: photo.latitude, longitude: photo.longitude)
        return homeZones.firstIndex { zone in
            let zoneLocation = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
            return location.distance(from: zoneLocation) < homeZoneRadius
        }
    }

    public func buildCluster(from photos: [PhotoLocationSnapshot]) async throws -> TravelCluster? {
        guard !photos.isEmpty else { return nil }

        let dates = photos.map { $0.createdAt }
        guard let startDate = dates.min(), let endDate = dates.max() else { return nil }

        // 1. 주소 있는 사진에서 먼저 수집
        let subLocalities = photos.compactMap { $0.subLocality }.filter { !$0.isEmpty}
        let localities = photos.compactMap { $0.locality }.filter { !$0.isEmpty }
        let administrativeAreas = photos.compactMap { $0.administrativeArea }.filter { !$0.isEmpty }
        let countries = photos.compactMap { $0.country }.filter { !$0.isEmpty }
        let isoCountryCodes = photos.compactMap { $0.isoCountryCode }.filter { !$0.isEmpty }

        // 2. 주소 없는 사진이 많으면 geocoding으로 보충
        let withoutAddress = photos.filter { $0.isoCountryCode == nil }
        var geocodedSubLocalities: [String] = []
        var geocodedLocalities: [String] = []
        var geocodedAdministrativeAreas: [String] = []
        var geocodedCountries: [String] = []
        var geocodedIsoCodes: [String] = []

        if !withoutAddress.isEmpty {
            let samples = sampleByGrid(withoutAddress)
            for snapshot in samples {
                let location = CLLocation(latitude: snapshot.latitude, longitude: snapshot.longitude)
                if let photoLocation = try? await geocoderService.fetchAddress(from: location, locale: Locale(identifier: "ko")) {
                    if let s = photoLocation.subLocality { geocodedSubLocalities.append(s) }
                    if let l = photoLocation.locality { geocodedLocalities.append(l) }
                    if let a = photoLocation.administrativeArea { geocodedAdministrativeAreas.append(a) }
                    if let c = photoLocation.country { geocodedCountries.append(c) }
                    if let i = photoLocation.isoCountryCode { geocodedIsoCodes.append(i) }
                }
            }
        }

        let allSubLocalities = subLocalities + geocodedSubLocalities
        let allLocalities = localities + geocodedLocalities
        let allAdministrativeAreas = administrativeAreas + geocodedAdministrativeAreas
        let allCountries = countries + geocodedCountries
        let allCodes = isoCountryCodes + geocodedIsoCodes

        // 3. 앨범명 결정
        let subLocality = mostFrequent(allSubLocalities) ?? ""
        let locality = resolveAlbumLocality(localities: allLocalities, administrativeAreas: allAdministrativeAreas)
        let administrativeArea = mostFrequent(allAdministrativeAreas) ?? ""
        let country = mostFrequent(allCountries) ?? ""
        let isoCode = mostFrequent(allCodes) ?? ""

        return TravelCluster(
            photos: photos,
            country: country,
            administrativeArea: administrativeArea,
            locality: locality,
            subLocality: subLocality,
            isoCountryCode: isoCode,
            startDate: startDate,
            endDate: endDate
        )
    }

    // 1km 그리드로 대표 좌표 샘플링
    private func sampleByGrid(_ photos: [PhotoLocationSnapshot]) -> [PhotoLocationSnapshot] {
        let grouped = Dictionary(grouping: photos) { snapshot -> String in
            let latKey = (snapshot.latitude * geocodingSampleGridSize).rounded()
            let lngKey = (snapshot.longitude * geocodingSampleGridSize).rounded()
            return "\(latKey),\(lngKey)"
        }
        return grouped.values.compactMap { $0.first }
    }

    // locality 분포 보고 시/도 결정
    private func resolveAlbumLocality(localities: [String], administrativeAreas: [String]) -> String? {
        guard !localities.isEmpty else {
            return administrativeAreas.isEmpty ? nil : mostFrequent(administrativeAreas)
        }

        let counts = localities.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        let total = localities.count

        if let top = counts.max(by: { $0.value < $1.value }) {
            let dominance = Double(top.value) / Double(total)
            if counts.keys.count == 1 || dominance >= localityDominanceThreshold {
                return top.key  // 시 단위
            }
        }

        return mostFrequent(administrativeAreas)  // 도 단위
    }

    private func mostFrequent(_ values: [String]) -> String? {
        guard !values.isEmpty else { return nil }
        let counts = values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
