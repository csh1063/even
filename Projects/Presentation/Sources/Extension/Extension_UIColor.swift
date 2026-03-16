//
//  Extension_UIColor.swift
//  Presentation
//
//  Created by sanghyeon on 3/13/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {

    class Theme {
    
        class var primary: UIColor { // DeepIndigo
            return UIColor(named: "primary") ?? UIColor("#5856D6")
        }
        class var secondary: UIColor { // SoftSlate
            return UIColor(named: "secondary") ?? UIColor("#8E8E93")
        }
        class var positive: UIColor { // MintGlass
            return UIColor(named: "positive") ?? UIColor("#34C759")
        }
        class var negative: UIColor { // RoseMadder
            return UIColor(named: "negative") ?? UIColor("#FF3B30")
        }
        class var white: UIColor { // PureWhite
            return UIColor(named: "white") ?? UIColor("#FFFFFF")
        }
        class var midnight: UIColor {
            return UIColor(named: "midnight") ?? UIColor("#1C1C1E")
        }
        class var obsidian: UIColor {
            return UIColor(named: "obsidian") ?? UIColor("#1F2021")
        }
        class var nickel: UIColor {
            return UIColor(named: "nickel") ?? UIColor("#93989E")
        }
        class var charcoal: UIColor {
            return UIColor(named: "charcoal") ?? UIColor("#4A4A4A")
        }
        class var gray: UIColor {
            return UIColor(named: "gray") ?? UIColor("#C0C3CC")
        }
        class var frost: UIColor {
            return UIColor(named: "frost") ?? UIColor("#EFF1F6")
        }
        class var platinum: UIColor {
            return UIColor(named: "platinum") ?? UIColor("#E5E7EF")
        }
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
