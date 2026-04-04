//
//  AlertButtonConfig.swift
//  Presentation
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit

public struct AlertButtonConfig {
    let title: String
    let style: Style
    let action: (() -> Void)?

    enum Style {
        case `default`
        case cancel
        case destructive

        var titleColor: UIColor {
            switch self {
            case .default:     return .Theme.positive
            case .cancel:      return .Theme.midnight.withAlphaComponent(0.8)
            case .destructive: return .Theme.negative
            }
        }

        var fontWeight: UIFont.Weight {
            switch self {
            case .cancel: return .semibold
            default:      return .regular
            }
        }
    }
}
