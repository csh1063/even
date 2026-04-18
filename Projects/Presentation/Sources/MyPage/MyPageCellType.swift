//
//  MyPageCellType.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

enum MyPageCellType: CaseIterable {
    case labels
    case test
    
    var text: String {
        switch self {
        case .labels: return "사진 라벨 목록"
        case .test: return "연구소"
        }
    }
}
