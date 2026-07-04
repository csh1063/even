//
//  NetworkService.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain

public final class NetworkService {

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

    func locationOverseas(_ photosInCoordi: [String: [Photo]]) async throws -> [AddressDTO] {
        var params = [OverseasParam]()
        for (coordiString, photos) in photosInCoordi {
            print("etcPhotos coordiString", coordiString)
            let coordi = coordiString.split(separator: ",")
            if coordi.count >= 2,
                let latitude = Double(coordi[0]),
                let longitude = Double(coordi[1]) {
                params.append(OverseasParam(ids: photos.map { $0.localIdentifier },
                                            lat: latitude,
                                            lng: longitude))
            }
        }
        return try await excuteor.request(GeoJsonAPI.coordiForOverseas(params))
    }

    func writeFeedback(_ feedback: FeedbackParam) async throws {
        let _: BaseNil = try await excuteor.request(SettingAPI.feedback(feedback))
    }
}
