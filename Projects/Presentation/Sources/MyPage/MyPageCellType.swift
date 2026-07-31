//
//  MyPageCellType.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

enum DisplayMode: String, CaseIterable {
    case system
    case light
    case dark

    init(_ key: String) {
        self = DisplayMode(rawValue: key) ?? .system
    }

    static func from(_ text: String) -> DisplayMode {
        DisplayMode.allCases.first { $0.text == text } ?? .system
    }

    var text: String {
        switch self {
        case .light: return String(localized: "라이트", bundle: .module)
        case .dark: return String(localized: "다크", bundle: .module)
        default: return String(localized: "시스템", bundle: .module)
        }
    }

    var style: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        default: return .unspecified
        }
    }

    var next: DisplayMode {
        switch self {
        case .system:
            return .light
        case .light:
            return .dark
        case .dark:
            return .system
        }
    }
}

enum MyPageCellStyle {
    case info
    case open // chevron.right
    case toggle
    case link // arrow.up.right
    case button

    var icon: String {
        switch self {
        case .open: return "chevron.right"
        case .link: return "arrow.up.right"
        default: return ""
        }
    }
}

enum MyPageCellType {

    // library
    case allLibraryPhoto
    case allPhoto
    case unanalysisPhoto

    // analysis
    case analyzedDate
    case analyzedData
    case analysis
    case reAutoAlbum
    case reset

    // background
    case locationAnalysis
    case locationAutoAlbum

    // switch
    case autoAnalysis
    case continueLocation

    // privacy
    case terms
    case privacy
    case openSource
    case photoPermission

    // app settings
    case displayMode
    case feedback
    case version

    case labels
    case test
    case addressCount

    var icon: String {
        switch self {
        case .allLibraryPhoto: return "photoLibrary"
        case .allPhoto: return "photo.on.rectangle.angled"
        case .unanalysisPhoto: return "lasso.badge.sparkles"
        case .analyzedDate: return "clock.arrow.circlepath"
        case .analysis: return "sparkles"
        case .analyzedData: return "cylinder.split.1x2"
        case .reAutoAlbum: return "arrow.clockwise"
        case .reset: return "eraser"
        case .locationAnalysis: return "location.fill.viewfinder"
        case .locationAutoAlbum: return "map.fill"
        case .autoAnalysis: return "sparkles"
        case .continueLocation: return "location.fill.viewfinder"
        case .terms: return "doc.text"
        case .privacy: return "person.2"
        case .openSource: return "ellipsis.curlybraces"
        case .photoPermission: return "photo.badge.checkmark"
        case .displayMode: return "circle.lefthalf.filled.inverse"
        case .feedback: return "questionmark.circle"
        case .version: return "info.circle"
        case .labels: return "testtube.2"
        case .test: return "testtube.2"
        case .addressCount: return "testtube.2"
        }
    }

    var text: String {
        switch self {
        case .allLibraryPhoto: return String(localized: "사진첩 사진 수", bundle: .module)
        case .allPhoto: return String(localized: "분석한 사진 수", bundle: .module)
        case .unanalysisPhoto: return String(localized: "미분석 사진 수", bundle: .module)
        case .analyzedDate: return String(localized: "최근 분석", bundle: .module)
        case .analyzedData: return String(localized: "분석 용량", bundle: .module)
        case .analysis: return String(localized: "분석하기", bundle: .module)
        case .reAutoAlbum: return String(localized: "자동 앨범 재생성", bundle: .module)
        case .reset: return String(localized: "분석 정보 삭제하기", bundle: .module)
        case .locationAnalysis: return String(localized: "사진 좌표를 주소로 변환", bundle: .module)
        case .locationAutoAlbum: return String(localized: "장소 기반 앨범 생성", bundle: .module)
        case .autoAnalysis: return String(localized: "새 사진 자동 분석", bundle: .module)
        case .continueLocation: return String(localized: "사진 좌표 이어서 분석", bundle: .module)
        case .terms: return String(localized: "서비스 이용약관", bundle: .module)
        case .privacy: return String(localized: "개인정보 처리방침", bundle: .module)
        case .openSource: return String(localized: "오픈소스 라이선스", bundle: .module)
        case .photoPermission: return String(localized: "사진 접근 범위", bundle: .module)
        case .displayMode: return String(localized: "디스플레이 모드", bundle: .module)
        case .feedback: return String(localized: "문의 / 피드백", bundle: .module)
        case .version: return String(localized: "앱 버전", bundle: .module)
        case .labels: return "사진 라벨 목록"
        case .test: return "연구소"
        case .addressCount: return "주소별 사진 수"
        }
    }

    var subText: String {
        switch self {
        case .locationAnalysis: return ""
        case .locationAutoAlbum: return ""
        default: return ""
        }
    }

    var style: MyPageCellStyle {
        switch self {
        case .allLibraryPhoto, .allPhoto, .unanalysisPhoto, .analyzedDate, .analyzedData:
            return .info
        case .analysis, .reset, .displayMode, .reAutoAlbum:
            return .button
        case .locationAnalysis, .locationAutoAlbum:
            return .info
        case .autoAnalysis, .continueLocation:
            return .toggle
        case .terms, .privacy/*, .displayMode*/, .openSource, .feedback:
            return .open
        case .version, .photoPermission:
            return .link
        case .labels, .test, .addressCount:
            return .open
        }
    }
}

struct MyCellData: Hashable {
    var type: MyPageCellType
    var value: String = ""
    var isOn: Bool = false

    var isPrimary: Bool = true
}

struct MyCellHeader: Hashable {
    var name: String
    var order: Int
}
