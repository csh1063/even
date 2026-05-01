//
//  MyPageCellType.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

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
    case reAnalysis
    
    // background
    case locationAnalysis
    case locationAutoFolder
    
    // switch
    case autoAnalysis
    
    // privacy
    case terms
    case privacy
    case photoPermission
    
    // app settings
    case displayMode
    case feedback
    case version
    
    case labels
    case test
    
    var icon: String {
        switch self {
        case .allLibraryPhoto: return "photoLibrary"
        case .allPhoto: return "photo.on.rectangle.angled"
        case .unanalysisPhoto: return "lasso.badge.sparkles"
        case .analyzedDate: return "clock.arrow.circlepath"
        case .analysis: return "sparkles"
        case .reAnalysis: return "arrow.clockwise"
        case .locationAnalysis: return "location.fill.viewfinder"
        case .locationAutoFolder: return "map.fill"
        case .autoAnalysis: return "sparkles"
        case .terms: return "doc.text"
        case .privacy: return "person.2"
        case .photoPermission: return "photo.badge.checkmark"
        case .displayMode: return "moon.fill"
        case .feedback: return "questionmark.circle"
        case .version: return "info.circle"
        case .labels: return ""
        case .test: return ""
        }
    }
    
    var text: String {
        switch self {
        case .allLibraryPhoto: return "사진첩 사진 수"
        case .allPhoto: return "분석한 사진 수"
        case .unanalysisPhoto: return "미분석 사진 수"
        case .analyzedDate: return "최근 분석"
        case .analysis: return "이어서 분석하기"
        case .reAnalysis: return "리셋 후 재분석하기"
        case .locationAnalysis: return "사진 좌표를 주소로 변환"
        case .locationAutoFolder: return "장소 기반 앨범 생성"
        case .autoAnalysis: return "새 사진 자동 분석"
        case .terms: return "이용 약관"
        case .privacy: return "개인 정보 처리 방침"
        case .photoPermission: return "사진 접근 범위"
        case .displayMode: return "다크 모드"
        case .feedback: return "문의 / 피드백"
        case .version: return "앱 버전"
        case .labels: return "사진 라벨 목록"
        case .test: return "연구소"
        }
    }
    
    var style: MyPageCellStyle {
        switch self {
        case .allLibraryPhoto, .allPhoto, .unanalysisPhoto, .analyzedDate:
            return .info
        case .analysis, .reAnalysis:
            return .button
        case .locationAnalysis, .locationAutoFolder:
            return .info
        case .autoAnalysis:
            return .toggle
        case .terms, .privacy, .photoPermission, .displayMode, .feedback, .version:
            return .open
        case .labels, .test:
            return .info
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
