import UIKit

//"Font-Light" = "Ubuntu-Light";
//"Font-DemiLight" = "Ubuntu-Light";
//"Font-Regular" = "Ubuntu";
//"Font-Medium" = "Ubuntu-Medium";
//"Font-Bold" = "Ubuntu-Bold";
//"Font-Bold-Medium" = "Ubuntu-Bold";
extension UIFont {
    // Localized Font
    class func boldLocalizedFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Font-Bold".localized, size: size) else {
            return UIFont.systemFont(ofSize: size, weight: .bold)
        }
        return font
    }

    class func lightLocalizedFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Font-Light".localized, size: size) else {
            return UIFont.systemFont(ofSize: size, weight: .light)
        }
        return font
    }

    class func demiLightLocalizedFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Font-DemiLight".localized, size: size) else {
            return UIFont.systemFont(ofSize: size, weight: .light)
        }
        return font
    }

    class func regularLocalizedFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Font-Regular".localized, size: size) else {
            return UIFont.systemFont(ofSize: size, weight: .regular)
        }
        return font
    }

    class func mediumLocalizedFont(ofSize size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Font-Medium".localized, size: size) else {
            return UIFont.systemFont(ofSize: size, weight: .medium)
        }
        return font
    }

//    class func semiBoldLocalizedFont(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "Font-Bold-Medium".localized, size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .semibold)
//        }
//        return font
//    }
//
//    // Ubuntu Font
//    class func boldUbuntu(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "Ubuntu-Bold", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .bold)
//        }
//        return font
//    }
//
//    class func lightUbuntu(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "Ubuntu-Light", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .light)
//        }
//        return font
//    }
//
//    class func regularUbuntu(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "Ubuntu", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .regular)
//        }
//        return font
//    }
//
//    class func mediumUbuntu(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "Ubuntu-Medium", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .medium)
//        }
//        return font
//    }
//
//    // NotoSansKR
//    class func boldNotoSansKR(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "NotoSansKR-Bold", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .bold)
//        }
//        return font
//    }
//
//    class func lightNotoSansKR(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "NotoSansKR-Light", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .light)
//        }
//        return font
//    }
//
//    class func demiLightNotoSansKR(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "NotoSansKR-DemiLight", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .ultraLight)
//        }
//        return font
//    }
//
//    class func regularNotoSansKR(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "NotoSansKR-Regular", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .regular)
//        }
//        return font
//    }
//
//    class func mediumNotoSansKR(ofSize size: CGFloat) -> UIFont {
//        guard let font = UIFont(name: "NotoSansKR-Medium", size: size) else {
//            return UIFont.systemFont(ofSize: size, weight: .medium)
//        }
//        return font
//    }
}
