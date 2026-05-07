//
//  TravelDetectionService.swift
//  Data
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import Foundation

public final class DefaultTravelDetectionRepository: TravelDetectionRepository {
    
    private let gapThreshold: TimeInterval = 3 * 24 * 60 * 60 // 3일
    
    public init() {}
    
    public func detect(from photos: [PhotoLocationSnapshot]) -> [TravelCluster] {
        let located = photos
            .filter { $0.country != nil && $0.country != "" && $0.administrativeArea != nil && $0.administrativeArea != ""}
            .sorted { $0.createdAt < $1.createdAt }
        
        guard !located.isEmpty else { return [] }
        
        var clusters: [[PhotoLocationSnapshot]] = []
        var current: [PhotoLocationSnapshot] = [located[0]]
        
        for i in 1..<located.count {
            let prev = located[i - 1]
            let curr = located[i]
            
            let sameCountry = prev.country == curr.country
            let sameArea = prev.administrativeArea == curr.administrativeArea
            let gap = curr.createdAt.timeIntervalSince(prev.createdAt)
            let withinGap = gap < gapThreshold
            
            if sameCountry && sameArea && withinGap {
                current.append(curr)
            } else {
                clusters.append(current)
                current = [curr]
            }
        }
        clusters.append(current)
        
        return clusters.compactMap { makeTravelCluster(from: $0) }
    }
    
    private func makeTravelCluster(from photos: [PhotoLocationSnapshot]) -> TravelCluster? {
        guard let first = photos.first,
              let country = first.country,
              let administrativeArea = first.administrativeArea else { return nil }
        
        // locality는 클러스터 내 가장 많이 등장한 값 사용
        let locality = mostFrequent(photos.compactMap { $0.locality })
        
        let dates = photos.compactMap { $0.createdAt }
        guard let startDate = dates.min(), let endDate = dates.max() else { return nil }
        
        return TravelCluster(
            photos: photos,
            country: country,
            administrativeArea: administrativeArea,
            locality: locality,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    private func mostFrequent(_ values: [String]) -> String? {
        guard !values.isEmpty else { return nil }
        let counts = values.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
