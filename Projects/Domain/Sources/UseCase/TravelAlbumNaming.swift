//
//  TravelAlbumNaming.swift
//  Domain
//
//  Created by sanghyeon on 7/16/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

/// 여행 앨범 이름 짓기 규칙 — 자동 생성(AutoAlbumUseCase)과 여행 합치기(AlbumDetailUseCase)가
/// 같은 알고리즘을 쓰도록 공용으로 뺀 순수 함수 모음
public enum TravelAlbumNaming {
    private static let administrativeAreaReplacements: [String: String] = [
        "전북특별자치도": "전라북도",
        "강원특별자치도": "강원도",
        "제주특별자치도": "제주도",
        "제주시": "제주도",
        "서귀포시": "제주도",
        "도쿄도": "도쿄"
    ]

    private static let suffixesToRemove = [
        "특별자치시", "특별광역시", "광역시", "특별시", "시"
    ]

    private static let suffixesForOverseas = [
        "부", "SAR", "특별행정구", "현", "시"
    ]

    public static func cleanAreaName(_ name: String, isoCode: String) -> String {
        var result = administrativeAreaReplacements[name] ?? name
        if isoCode.uppercased() == "KR" {
            for suffix in suffixesToRemove {
                if result.hasSuffix(suffix) {
                    result = String(result.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        } else {
            for suffix in suffixesForOverseas {
                if result.uppercased().hasSuffix(suffix.uppercased()) {
                    result = String(result.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        return result
    }

    /// 하루짜리 여행은 "여행"보다 "나들이"가 더 자연스럽다 (출발/도착 구분이 무의미한 짧은 일정)
    public static func displayName(place: String, startDate: Date, endDate: Date) -> String {
        let isSingleDay = Calendar.current.isDate(startDate, inSameDayAs: endDate)
        return isSingleDay ? "\(place) 나들이" : "\(place) 여행"
    }
}
