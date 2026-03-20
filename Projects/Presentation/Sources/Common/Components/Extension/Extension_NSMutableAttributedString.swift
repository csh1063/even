import UIKit

// AttributedString 생성시 Builder를 통해 간편하게 생성하도록 확장
extension NSMutableAttributedString {

    final class Builder {

        private var mutableAttributedString: NSMutableAttributedString

        // Builder 생성
        init(string str: String, attributes attrs: [NSAttributedString.Key: Any]? = nil) {
            mutableAttributedString = NSMutableAttributedString(string: str, attributes: attrs)
        }

        // attributedString 연결
        func append(string str: String, attributes attrs: [NSAttributedString.Key: Any]? = nil) -> Builder {
            mutableAttributedString.append(NSMutableAttributedString(string: str, attributes: attrs))
            return self
        }

        // build
        func build() -> NSMutableAttributedString {
            return mutableAttributedString
        }
    }

}

extension NSAttributedString {
    convenience init(htmlString html: String, font: UIFont? = nil, useDocumentFontSize: Bool = true) throws {
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let data = html.data(using: .utf8, allowLossyConversion: true), let fontFamily = font?.familyName,
            let attr = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) else {
            try self.init(data: Data(html.utf8), options: options, documentAttributes: nil)
            return
        }

        let fontSize: CGFloat? = useDocumentFontSize ? nil : (font?.pointSize ?? 15)
        let range = NSRange(location: 0, length: attr.length)
        attr.enumerateAttribute(.font, in: range, options: .longestEffectiveRangeNotRequired) { attrib, range, _ in
            if let htmlFont = attrib as? UIFont {
                let traits = htmlFont.fontDescriptor.symbolicTraits
                var descrip = htmlFont.fontDescriptor.withFamily(fontFamily)

                if (traits.rawValue & UIFontDescriptor.SymbolicTraits.traitBold.rawValue) != 0,
                    let result = descrip.withSymbolicTraits(.traitBold) {
                    descrip = result
                }

                if (traits.rawValue & UIFontDescriptor.SymbolicTraits.traitItalic.rawValue) != 0,
                    let result = descrip.withSymbolicTraits(.traitItalic) {
                    descrip = result
                }

                attr.addAttribute(.font, value: UIFont(descriptor: descrip, size: fontSize ?? htmlFont.pointSize),
                                  range: range)
            }
        }
        self.init(attributedString: attr)
    }
}
