//
//  HomeZone.swift
//  Domain
//
//  Created by sanghyeon on 5/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreLocation
import Foundation

// Domain 모듈
public struct HomeZone {
    public let latitude: Double
    public let longitude: Double
    public let analyzedAt: Date

    public init(latitude: Double, longitude: Double, analyzedAt: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.analyzedAt = analyzedAt
    }
}

public extension HomeZone {
    // 홈존 위경도 기준으로 가장 가까운 사진의 주소를 찾아 사람이 알아볼 수 있는 문자열로 변환
    func addressDescription(in photos: [PhotoLocationSnapshot]) -> String {
        let zoneLocation = CLLocation(latitude: latitude, longitude: longitude)
        guard let nearest = photos
            .filter({ $0.latitude != 0 || $0.longitude != 0 })
            .min(by: {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: zoneLocation)
                < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: zoneLocation)
            })
        else {
            return "주소 확인 불가 (lat: \(latitude), lng: \(longitude))"
        }

        let components = [nearest.country, nearest.administrativeArea, nearest.locality, nearest.subLocality]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { result, value in
                if !result.contains(value) { result.append(value) }
            }

        return components.isEmpty ? "주소 확인 불가 (lat: \(latitude), lng: \(longitude))" : components.joined(separator: ", ")
    }
}
