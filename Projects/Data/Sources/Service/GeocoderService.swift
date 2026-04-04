//
//  GeocoderService.swift
//  Data
//
//  Created by sanghyeon on 3/20/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import CoreLocation
import Domain

public final class GeocoderService {

    // MARK: - 단어 목록 로드
    private let replaceTerms: [String: String] = {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "ReplaceWord", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            print("replaceTerms else")
            return [:]
        }
        for (key, value) in dict {
            print("replaceTerms key:", key, ", value:", value)
        }
        return dict
    }()
    
    public init() {
        
    }

    // MARK: - Public
    func fetchAddress(from location: CLLocation, id: String, locale: Locale = .current) async throws -> PhotoLocation? {
        
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                location,
                preferredLocale: locale
            )
            
            guard let data = placemarks.first else { return PhotoLocation() }
            
            let location = mapping(of: data)
            return location
        } catch {
            print("error")
            return PhotoLocation()
        }
    }

    // MARK: - Private
    private func replaceAddress(_ string: String?) -> String {
        guard let string else { return "" }
        
        for (key, value) in self.replaceTerms where key == string {
            return value
        }
        return string
    }

    private func mapping(of placemark: CLPlacemark) -> PhotoLocation {
        PhotoLocation(
            country: replaceAddress(placemark.country),
            administrativeArea: replaceAddress(placemark.administrativeArea),
            locality: replaceAddress(placemark.locality),
            subLocality: replaceAddress(placemark.subLocality),
            thoroughfare: replaceAddress(placemark.thoroughfare),
            ocean: replaceAddress(placemark.ocean),
            isoCountryCode: placemark.isoCountryCode)
    }
}
