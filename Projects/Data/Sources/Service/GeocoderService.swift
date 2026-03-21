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
    private static let blockedTerms: Set<String> = {
        let bundle = Bundle(for: GeocoderService.self)
        guard let url = bundle.url(forResource: "BlockedWord", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let array = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(array)
    }()

    private static let replaceTerms: [String: String] = {
        let bundle = Bundle(for: GeocoderService.self)
        guard let url = bundle.url(forResource: "ReplaceWord", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }()
    
    public init() {
        
    }

    // MARK: - Public
    func fetchAddress(from location: CLLocation, id: String) async throws -> [PhotoLabel] {
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                location,
                preferredLocale: .current
            )
            
            guard let placemark = placemarks.first else { return [] }

            let finalPlacemark: CLPlacemark

            if containsBlockedTerm(in: placemark) {
                // 2차: 영어로 재요청
                let enPlacemarks = try await geocoder.reverseGeocodeLocation(
                    location,
                    preferredLocale: Locale(identifier: "en")
                )
                finalPlacemark = enPlacemarks.first ?? placemark
            } else {
                finalPlacemark = placemark
            }

            // 주소 조합 — 영어 폴백 결과에 차단 단어 남아있으면 해당 필드 제거
            let address = buildAddress(from: finalPlacemark)

            // 변경 단어 치환
            return applyReplacements(to: address).map {
                PhotoLabel(name: $0.lowercased(), confidence: 1.0)
            }
        } catch {
            return []
        }
    }

    // MARK: - Private

    private func containsBlockedTerm(in placemark: CLPlacemark) -> Bool {
        allFields(of: placemark).contains { field in
            Self.blockedTerms.contains { term in field.contains(term) }
        }
    }

    private func buildAddress(from placemark: CLPlacemark) -> [String] {
        self.allFields(of: placemark)
        .compactMap { $0 }
        .filter { field in
            // 차단 단어가 남아있으면 제거
            return !Self.blockedTerms.contains { term in field.contains(term) }
        }
    }

    private func applyReplacements(to address: [String]) -> [String] {
        let replaced = address.map { field in
            Self.replaceTerms.reduce(field) { result, pair in
                result.replacingOccurrences(of: pair.key, with: pair.value)
            }
        }
        return replaced
    }

    private func allFields(of placemark: CLPlacemark) -> [String] {
        [
            placemark.name, // 강남파이낸스센터
            placemark.thoroughfare, // 테헤란로
            placemark.subThoroughfare, // 152
            placemark.locality, // 서울특별시
            placemark.subLocality, // 강남구
            placemark.administrativeArea, // 서울특별시
            placemark.subAdministrativeArea, // 군? 한국에선 거의 안나오지만 나올수도?
            placemark.postalCode, // 06236
            placemark.isoCountryCode,  // KR
            placemark.country, // 대한민국
            placemark.inlandWater, // nil 호수 이름?
            placemark.ocean   // nil 바다 이름
        ].compactMap { $0 }
    }
}
