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
    case next
    case confirm
    case more
    case add
    case close
    case select
//    case filter
//    case report
//    case finder
//    case clearText
//    case toggleList
//    case setting
//    case write
//    case analysis
//    case reset
//    case text(String)
//    case sectionGrid
//    case grid
//    case edit
//    case delete

    var imageName: String {
        switch self {
        case .none: return ""
        case .back: return "chevron.backward"
        case .cancel: return "xmark"
        case .next: return "chevron.forward"
        case .confirm: return "checkmark"
        case .more: return "ellipsis"
        case .add: return "plus"
        case .close: return "xmark"
        case .select: return ""
//        case .filter: return "line.3.horizontal.decrease"
//        case .report: return "exclamationmark.bubble"
//        case .finder: return "magnifyingglass"
//        case .clearText: return "xmark.circle"
//        case .toggleList: return "list.dash.header.rectangle"
//        case .setting: return "gearshape"
//        case .write: return "pencil"
//        case .analysis: return "sparkles"
//        case .reset: return "arrow.clockwise"
//        case .text: return ""
//        case .sectionGrid: return "square.grid.3x1.below.line.grid.1x2"
//        case .grid: return "square.grid.3x3"
//        case .edit: return "pencil.line"
//        case .delete: return "trash"
        }
    }

    var text: String? {
        switch self {
//        case .analysis: return "분석"
//        case .text(let text): return text
        case .select: return String(localized: "선택", bundle: .module)
        default: return nil
        }
    }

    var backgroundColor: UIColor? {
        switch self {
//        case .analysis: return Theme.primary
        case .more, .cancel, .add, .select: return Theme.surface.withAlphaComponent(0.95)
        default: return nil
        }
    }

    var foregroundColor: UIColor {
        switch self {
//        case .analysis: return .white
//        case .add: return Theme.primary
        default: return Theme.textPrimary
        }
    }

    var font: UIFont? {
        switch self {
//        case .analysis: return .systemFont(ofSize: 15, weight: .semibold)
        default: return nil
        }
    }
}
