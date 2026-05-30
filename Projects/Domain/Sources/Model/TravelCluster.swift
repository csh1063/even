//
//  TravelCluster.swift
//  Domain
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct TravelCluster {
    public let photos: [PhotoLocationSnapshot]
    public let country: String
    public let administrativeArea: String
    public let locality: String?
    public let startDate: Date
    public let endDate: Date
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    

    public var folderName: String {
        let raw = locality?.isEmpty == false ? locality! :
                  administrativeArea.isEmpty ? country :
                  administrativeArea
        let place = cleanAreaName(raw)
        return "\(place) · \(Self.dateFormatter.string(from: startDate))"
    }
//    public var folderName: String {
//        let place = locality?.isEmpty == false ? locality! :
//                    administrativeArea.isEmpty ? country :
//                    administrativeArea
//        return "\(place) · \(Self.dateFormatter.string(from: startDate))"
//    }
    
    public var folderDisplayName: String { folderName }
    
    public init(
        photos: [PhotoLocationSnapshot],
        country: String,
        administrativeArea: String,
        locality: String?,
        startDate: Date,
        endDate: Date
    ) {
        self.photos = photos
        self.country = country
        self.administrativeArea = administrativeArea
        self.locality = locality
        self.startDate = startDate
        self.endDate = endDate
    }
    
    private static let administrativeAreaReplacements: [String: String] = [
        "전북특별자치도": "전라북도",
        "강원특별자치도": "강원도",
        "제주특별자치도": "제주도"
    ]

    private static let suffixesToRemove = [
        "특별자치시", "특별광역시", "광역시", "특별시", "시"
    ]

    private func cleanAreaName(_ name: String) -> String {
        var result = Self.administrativeAreaReplacements[name] ?? name
        for suffix in Self.suffixesToRemove {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
                break
            }
        }
        return result
    }
}
