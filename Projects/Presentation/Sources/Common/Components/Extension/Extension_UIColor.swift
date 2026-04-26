//
//  Extension_UIColor.swift
//  Presentation
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

enum Theme {
    static let primary = UIColor.named("primary")
    static let secondary = UIColor.named("secondary")
    static let accent = UIColor.named("accent")

    static let positive = UIColor.named("positive")
    static let warning = UIColor.named("warning")
    static let negative = UIColor.named("negative")

    static let background = UIColor.named("background")
    static let surface = UIColor.named("surface")
    static let surfaceElevated = UIColor.named("surfaceElevated")
    static let surfaceWarm = UIColor.named("surfaceWarm")
    static let surfaceCool = UIColor.named("surfaceCool")

    static let textPrimary = UIColor.named("textPrimary")
    static let textSecondary = UIColor.named("textSecondary")
    static let textTertiary = UIColor.named("textTertiary")

    static let strokeSoft = UIColor.named("strokeSoft")
    static let strokeStrong = UIColor.named("strokeStrong")
    static let divider = UIColor.named("divider")

    static let viewerBackground = UIColor.named("viewerBackground")
}

extension UIColor {
    
    static func named(_ name: String) -> UIColor {
        UIColor(named: name, in: .module, compatibleWith: nil) ?? .clear
    }

    convenience init(redInt: Int, greenInt: Int, blueInt: Int, alpha: CGFloat) {
        self.init(red: CGFloat(redInt) / 255, green: CGFloat(greenInt) / 255,
                  blue: CGFloat(blueInt) / 255, alpha: alpha)
    }

    convenience init(rgbInt: Int, alpha: CGFloat) {
        self.init(redInt: rgbInt, greenInt: rgbInt, blueInt: rgbInt, alpha: alpha)
    }

    convenience init(_ rgb: String, alpha: CGFloat = 1.0) {
        guard rgb.hasPrefix("#") else {
            fatalError("rgb does not start with a #.")
        }

        let hexString = String(rgb[rgb.index(rgb.startIndex, offsetBy: 1) ..< rgb.endIndex])

        guard hexString.count == 6 else {
            fatalError("hexString has an invalid length.")
        }

        guard let hexValue = UInt32(hexString, radix: 16) else {
            fatalError("hexString is not a hexadecimal.")
        }

        let red = CGFloat((hexValue & 0xFF0000) >> 16) / CGFloat(255)
        let green = CGFloat((hexValue & 0x00FF00) >> 8) / CGFloat(255)
        let blue = CGFloat(hexValue & 0x0000FF) / CGFloat(255)

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
