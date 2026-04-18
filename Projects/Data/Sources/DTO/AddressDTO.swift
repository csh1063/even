//
//  AddressDTO.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

struct AddressDTO: Decodable {
    let id: String
    let isKorea: Bool
    let administrativeArea: String?
    let locality: String?
    let subLocality: String?
    let thoroughfare: String?
}
