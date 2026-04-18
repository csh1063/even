//
//  AddressDTOMapper.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

extension AddressDTO {
    func toKRDomain() -> PhotoLocation {
        return PhotoLocation(
            thoroughfare: thoroughfare,
            locality: locality,
            subLocality: subLocality,
            administrativeArea: administrativeArea,
            isoCountryCode: "KR",
            country: "대한민국"
        )
    }
}
