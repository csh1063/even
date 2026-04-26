//
//  NaviBarType.swift
//  Presentation
//
//  Created by sanghyeon on 3/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

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
        case .back: return "chevron.backward"
        case .cancel: return "xmark"
        case .filter: return "line.3.horizontal.decrease"
        case .report: return "exclamationmark.bubble"
        case .next: return "chevron.forward"
        case .finder: return "magnifyingglass"
        case .clearText: return "xmark.circle"
        case .toggleList: return "list.dash.header.rectangle"
        case .confirm: return "checkmark"
        case .setting: return "gearshape"
        case .write: return "pencil"
        case .analysis: return "sparkles"
        case .reset: return "arrow.clockwise"
        case .text: return ""
        case .sectionGrid: return "square.grid.3x1.below.line.grid.1x2"
        case .grid: return "square.grid.3x3"
        case .more: return "ellipsis.circle"
        case .edit: return "pencil.line"
        case .delete: return "trash"
        }
    }
    
    var text: String? {
        switch self {
        case .analysis: return "분석"
        case .text(let text): return text
        default: return nil
        }
    }
    
    var backgroundColor: UIColor? {
        switch self {
        case .analysis: return Theme.primary
        case .more, .reset: return Theme.surface.withAlphaComponent(0.95)
        default: return nil
        }
    }
    
    var foregroundColor: UIColor {
        switch self {
        case .analysis: return .white
        default: return Theme.textPrimary
        }
    }
    
    var font: UIFont? {
        switch self {
        case .analysis: return .systemFont(ofSize: 15, weight: .semibold)
        default: return nil
        }
    }
}
