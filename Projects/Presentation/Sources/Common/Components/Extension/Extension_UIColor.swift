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
    static let primary: UIColor = UIColor.named("primary")
    static let secondary: UIColor = UIColor.named("secondary")
    static let accent: UIColor = UIColor.named("accent")
    static let support: UIColor = UIColor.named("support")
    static let background: UIColor = UIColor.named("background")
    static let surface: UIColor = UIColor.named("surface")
    static let surfaceAlt: UIColor = UIColor.named("surface_alt")
    static let text: UIColor = UIColor.named("text")
    static let textSecond: UIColor = UIColor.named("textSecond")
    static let border: UIColor = UIColor.named("border")
    static let positive: UIColor = UIColor.named("positive")
    static let negative: UIColor = UIColor.named("negative")
    static let warning: UIColor = UIColor.named("warning")
    static let info: UIColor = UIColor.named("info")
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
