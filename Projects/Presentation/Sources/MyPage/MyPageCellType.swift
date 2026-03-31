//
//  MyPageCellType.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

enum MyPageCellType {
    case labels
    
    var text: String {
        switch self {
        case .labels: return "사진 라벨 목록"
        }
    }
}
