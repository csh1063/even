//
//  PhotoLocation.swift
//  Domain
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public struct PhotoLocation: Codable {
    public var country: String?               // 대한민국
    public var administrativeArea: String?    // 서울특별시
    public var locality: String?              // 서울특별시
    public var subLocality: String?           // 강남구
    public var thoroughfare: String?          // 테헤란로
    public var ocean: String?                 // nil 바다 이름
    
    public init(country: String? = nil,
                administrativeArea: String? = nil,
                locality: String? = nil,
                subLocality: String? = nil,
                thoroughfare: String? = nil,
                ocean: String? = nil) {
        self.country = country
        self.administrativeArea = administrativeArea
        self.locality = locality
        self.subLocality = subLocality
        self.thoroughfare = thoroughfare
        self.ocean = ocean
    }
}
