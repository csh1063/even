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
        /// 메인 액션, 브랜드 색 WarmSand
        class var primary: UIColor {
            return UIColor(named: "primary") ?? UIColor("#C8A882")
        }
        /// 보조 요소 DustyRose
        class var secondary: UIColor {
            return UIColor(named: "secondary") ?? UIColor("#A07868")
        }
        /// 힌트/비활성 WarmTaupe / MutedStone
        class var tertiary: UIColor {
            return UIColor(named: "tertiary") ?? UIColor("#8E8278")
        }
        /// 배경 WarmIvory / InkBlack
        class var background: UIColor {
            return UIColor(named: "background") ?? UIColor("#EDE5D8")
        }
        /// 카드/시트 배경 CreamIvory / SoftCharcoal
        class var surface: UIColor {
            return UIColor(named: "surface") ?? UIColor("#F5EFE4")
        }
        /// 텍스트 DeepEspresso /. ParchmentWhite
        class var text: UIColor {
            return UIColor(named: "text") ?? UIColor("#1E1612")
        }
        /// 텍스트 서브 SoftEspresso / WarmGray
        class var textSecond: UIColor {
            return UIColor(named: "textSecond") ?? UIColor("#5A4A3C")
        }
        /// 테두리/분리선 WarmBorder / DimBorder
        class var border: UIColor {
            return UIColor(named: "border") ?? UIColor("#CEC4B4")
        }
        /// 긍정 SageGreen
        class var positive: UIColor {
            return UIColor(named: "positive") ?? UIColor("#7A9E7E")
        }
        /// 부정 WarmCrimson
        class var negative: UIColor {
            return UIColor(named: "negative") ?? UIColor("#C0392B")
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
