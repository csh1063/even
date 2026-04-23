//
//  NaviBarType.swift
//  Presentation
//
//  Created by sanghyeon on 3/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

enum NaviBarType {
    case title(NaviBarTitleAlign)
    case logo
}

enum NaviBarTitleAlign {
    case center
    case leading
}

enum NaviBarButtonType: Equatable {
    case none
    case back
    case cancel
    case filter
    case report
    case next
    case finder
    case clearText
    case toggleList
    case confirm
    case setting
    case write
    case analysis
    case reset
    case text(String)
    case sectionGrid
    case grid
    case more
    case edit
    case delete
    
    var imageName: String {
        switch self {
        case .none: return ""
        case .back: return "arrow.backward"
        case .cancel: return "xmark"
        case .filter: return "line.3.horizontal.decrease"
        case .report: return "exclamationmark.bubble"
        case .next: return "arrow.forward"
        case .finder: return "magnifyingglass"
        case .clearText: return "xmark.circle"
        case .toggleList: return "list.dash.header.rectangle"
        case .confirm: return "checkmark"
        case .setting: return "gearshape"
        case .write: return "pencil"
        case .analysis: return "sparkles.tv"
        case .reset: return "arrow.clockwise"
        case .text: return ""
        case .sectionGrid: return "square.grid.3x1.below.line.grid.1x2"
        case .grid: return "square.grid.3x3"
        case .more: return "ellipsis"
        case .edit: return "pencil.line"
        case .delete: return "trash"
        }
    }
}
