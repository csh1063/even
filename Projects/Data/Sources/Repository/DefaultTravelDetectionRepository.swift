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
    private let moveDistanceThreshold: Double = 55_000
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
            
            if isInHomeZone(currSnapshot, homeZones: homeZones) {
                print("홈존으로 제거", currSnapshot.country, currSnapshot.administrativeArea, currSnapshot.locality)
                rawClusters.append(current)
                current = []
                continue
            }
            
            // prev가 홈존이었으면 gap/distance 계산 스킵하고 그냥 추가
            if isInHomeZone(prevSnapshot, homeZones: homeZones) {
//                current.append(located[i])
                current = [located[i]]
                continue
            }
            
            let gap = currSnapshot.createdAt.timeIntervalSince(prevSnapshot.createdAt)
            let distance = currLocation.distance(from: prevLocation)
            let isNormalStepping = gap < timeGapThreshold && distance < moveDistanceThreshold
            
//            if gap / 86400 > 5 && isNormalStepping {
//                print("⚠️ 6일 이상 gap인데 묶임: \(gap / 86400)일, distance: \(distance)")
//                print("prev: \(prevSnapshot.createdAt), \(prevSnapshot.locality)")
//                print("curr: \(currSnapshot.createdAt), \(currSnapshot.locality)")
//            }
//            print("gap days: \(gap / 86400), distance: \(distance), isNormalStepping: \(isNormalStepping)")
//            print("prev: \(prevSnapshot.createdAt), \(prevSnapshot.locality)")
//            print("curr: \(currSnapshot.createdAt), \(currSnapshot.locality)")
            
            if isNormalStepping {
                current.append(located[i])
            } else {
                rawClusters.append(current)
                current = [located[i]]
            }
        }
        
        rawClusters.append(current)
        
        let filteredClusters = rawClusters.filter { $0.count >= minimumClusterSize }
        
        var result: [TravelCluster] = []
        for raw in filteredClusters {
            let snapshots = raw.map { $0.0 }
            if let cluster = try await makeTravelCluster(from: snapshots) {
                result.append(cluster)
            }
        }
        return result
    }
    
    private func isInHomeZone(_ photo: PhotoLocationSnapshot, homeZones: [HomeZone]) -> Bool {
        let location = CLLocation(latitude: photo.latitude, longitude: photo.longitude)
        return homeZones.contains { zone in
            let zoneLocation = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
            return location.distance(from: zoneLocation) < homeZoneRadius
        }
    }
    
    private func makeTravelCluster(from photos: [PhotoLocationSnapshot]) async throws -> TravelCluster? {
        guard !photos.isEmpty else { return nil }
        
        let dates = photos.map { $0.createdAt }
        guard let startDate = dates.min(), let endDate = dates.max() else { return nil }
        
        // 1. 주소 있는 사진에서 먼저 수집
        let localities = photos.compactMap { $0.locality }.filter { !$0.isEmpty }
        let administrativeAreas = photos.compactMap { $0.administrativeArea }.filter { !$0.isEmpty }
        let countries = photos.compactMap { $0.country }.filter { !$0.isEmpty }
        let isoCountryCodes = photos.compactMap { $0.isoCountryCode }.filter { !$0.isEmpty }
        
        // 2. 주소 없는 사진이 많으면 geocoding으로 보충
        let withoutAddress = photos.filter { $0.locality == nil && $0.administrativeArea == nil }
        var geocodedLocalities: [String] = []
        var geocodedAdministrativeAreas: [String] = []
        var geocodedCountries: [String] = []
        var geocodedIsoCodes: [String] = []
        
        if !withoutAddress.isEmpty {
            let samples = sampleByGrid(withoutAddress)
            for snapshot in samples {
                let location = CLLocation(latitude: snapshot.latitude, longitude: snapshot.longitude)
                if let photoLocation = try? await geocoderService.fetchAddress(from: location, locale: Locale(identifier: "ko")) {
                    if let l = photoLocation.locality { geocodedLocalities.append(l) }
                    if let a = photoLocation.administrativeArea { geocodedAdministrativeAreas.append(a) }
                    if let c = photoLocation.country { geocodedCountries.append(c) }
                    if let i = photoLocation.isoCountryCode { geocodedIsoCodes.append(i) }
                }
            }
        }
        
        let allLocalities = localities + geocodedLocalities
        let allAdministrativeAreas = administrativeAreas + geocodedAdministrativeAreas
        let allCountries = countries + geocodedCountries
        let allCodes = isoCountryCodes + geocodedIsoCodes
        
        // 3. 폴더명 결정
        let locality = resolveAlbumLocality(localities: allLocalities, administrativeAreas: allAdministrativeAreas)
        let administrativeArea = mostFrequent(allAdministrativeAreas) ?? ""
        let country = mostFrequent(allCountries) ?? ""
        let isoCode = mostFrequent(allCodes) ?? ""
        
        return TravelCluster(
            photos: photos,
            country: country,
            administrativeArea: administrativeArea,
            locality: locality,
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
