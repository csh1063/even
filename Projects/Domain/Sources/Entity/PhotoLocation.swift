//
//  PhotoLocation.swift
//  Domain
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public struct PhotoLocation: Codable, Equatable {
//    public var country: String?               // 대한민국
//    public var administrativeArea: String?    // 서울특별시
//    public var locality: String?              // 서울특별시
//    public var subLocality: String?           // 강남구
//    public var thoroughfare: String?          // 테헤란로
//    public var ocean: String?                 // nil 바다 이름
//    public var isoCountryCode: String?
    
    public var name: String?
    public var thoroughfare: String?
    public var subThoroughfare: String?
    public var locality: String?
    public var subLocality: String?
    public var administrativeArea: String?
    public var subAdministrativeArea: String?
    public var postalCode: String?
    public var isoCountryCode: String?
    public var country: String?
    public var inlandWater: String?
    public var ocean: String?
    
    public init(
        name: String? = nil,
        thoroughfare: String? = nil,
        subThoroughfare: String? = nil,
        locality: String? = nil,
        subLocality: String? = nil,
        administrativeArea: String? = nil,
        subAdministrativeArea: String? = nil,
        postalCode: String? = nil,
        isoCountryCode: String? = nil,
        country: String? = nil,
        inlandWater: String? = nil,
        ocean: String? = nil
    ) {
        print("name:", name ?? "nil",
              "thoroughfare:", thoroughfare ?? "nil",
              "subThoroughfare:", subThoroughfare ?? "nil",
              "locality:", locality ?? "nil",
              "subLocality:", subLocality ?? "nil",
              "administrativeArea:", administrativeArea ?? "nil",
              "subAdministrativeArea:", subAdministrativeArea ?? "nil",
              "postalCode:", postalCode ?? "nil",
              "isoCountryCode:", isoCountryCode ?? "nil",
              "country:", country ?? "nil",
              "inlandWater:", inlandWater ?? "nil",
              "ocean:", ocean ?? "nil")
        
        self.name = name
        self.thoroughfare = thoroughfare
        self.subThoroughfare = subThoroughfare
        self.locality = locality
        self.subLocality = subLocality
        self.administrativeArea = administrativeArea
        self.subAdministrativeArea = subAdministrativeArea
        self.postalCode = postalCode
        self.isoCountryCode = isoCountryCode
        self.country = country
        self.inlandWater = inlandWater
        self.ocean = ocean
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.country == rhs.country
        && lhs.administrativeArea == rhs.administrativeArea
        && lhs.locality == rhs.locality
        && lhs.subLocality == rhs.subLocality
        && lhs.thoroughfare == rhs.thoroughfare
        && lhs.ocean == rhs.ocean
        && lhs.isoCountryCode == rhs.isoCountryCode
    }
}
