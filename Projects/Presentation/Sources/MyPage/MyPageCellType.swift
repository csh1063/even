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
        case .light: return "라이트"
        case .dark: return "다크"
        default: return "시스템"
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
    case analysis
    case travelAlbum
    case reAutoAlbum
    case reAnalysis
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
        case .travelAlbum: return "globe.desk"
        case .reAutoAlbum: return "arrow.clockwise"
        case .reAnalysis: return "arrow.clockwise"
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
        case .allLibraryPhoto: return "사진첩 사진 수"
        case .allPhoto: return "분석한 사진 수"
        case .unanalysisPhoto: return "미분석 사진 수"
        case .analyzedDate: return "최근 분석"
        case .analysis: return "분석하기"
        case .travelAlbum: return "여행 폴더 만들기"
        case .reAutoAlbum: return "자동 폴더 재생성"
        case .reAnalysis: return "처음부터 분석하기"
        case .reset: return "분석 정보 삭제하기"
        case .locationAnalysis: return "사진 좌표를 주소로 변환"
        case .locationAutoAlbum: return "장소 기반 앨범 생성"
        case .autoAnalysis: return "새 사진 자동 분석"
        case .continueLocation: return "사진 좌표 이어서 분석"
        case .terms: return "이용 약관"
        case .privacy: return "개인 정보 처리 방침"
        case .openSource: return "오픈소스 라이선스"
        case .photoPermission: return "사진 접근 범위"
        case .displayMode: return "디스플레이 모드"
        case .feedback: return "문의 / 피드백"
        case .version: return "앱 버전"
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
        case .allLibraryPhoto, .allPhoto, .unanalysisPhoto, .analyzedDate:
            return .info
        case .analysis, .travelAlbum, .reAnalysis, .reset, .displayMode, .reAutoAlbum:
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
