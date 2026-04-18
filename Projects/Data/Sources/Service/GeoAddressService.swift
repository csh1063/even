//
//  GeoAddressService.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain

public final class GeoAddressService {
    
    private let excuteor: DefaultNetworkExecutor
    
    public init(excuteor: DefaultNetworkExecutor) {
        self.excuteor = excuteor
    }
    
    func locationToAddress(_ photos: [Photo]) async throws -> [AddressDTO] {
        let params = photos.compactMap {
            if let latitude = $0.latitude, let longitude = $0.longitude {
                return LocationParam(id: $0.localIdentifier,
                                     lat: latitude,
                                     lng: longitude)
            }
            return nil
        }
        return try await excuteor.request(GeoJsonAPI.coordiToAddress(params))
    }
}
