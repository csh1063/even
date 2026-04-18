//
//  DefaultGeoRepository.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

public final class DefaultGeoRepository: GeoRepository {
    
    private let service: GeoAddressService
    
    public init(service: GeoAddressService) {
        self.service = service
    }
    
    public func locationToaddress(_ photos: [Photo]) async throws -> [String: PhotoLocation] {
        var result: [String: PhotoLocation] = [:]
        for address in try await self.service.locationToAddress(photos) where address.isKorea {
            result[address.id] = address.toKRDomain()
        }
        return result
    }
}
