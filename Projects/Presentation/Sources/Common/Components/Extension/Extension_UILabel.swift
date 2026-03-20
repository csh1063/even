import UIKit

// 레이블 기능 확장
extension UILabel {

    var substituteFontName: String {
        get { return self.font.fontName }
        set { self.font = UIFont(name: newValue, size: 20) }
    }

    // 텍스트 밑줄 지정
    func setUnderLine() {
        let text = self.text ?? ""
        let attributedText = NSAttributedString(string: text, attributes:
            [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        self.attributedText = attributedText
    }

    // 여기부터 chaining 함수 (override 의 경우 view의 chaining 함수 override)
    // 글자 색 지정 후 반환
    func withTextColor(_ textColor: UIColor) -> UILabel {
        setTextColor(textColor)
        return self
    }

    func setTextColor(_ textColor: UIColor) {
        self.textColor = textColor
    }

    // 폰트 지정 후 반환
    func withFont(_ font: UIFont?) -> UILabel {
        setFont(font)
        return self
    }

    func setFont(_ font: UIFont?) {
        self.font = font
    }

    // lineBreakMode 지정 후 반환
    func withLineBreakMode(_ lineBreakMode: NSLineBreakMode) -> UILabel {
        self.lineBreakMode = lineBreakMode
        return self
    }

    // numberOfLines 지정 후 반환
    func withNumberOfLines(_ numberOfLines: Int) -> UILabel {
        self.numberOfLines = numberOfLines
        return self
    }

    func setText(_ text: String, kern: CGFloat? = nil, isLine: Bool = false, lineHeightMultiple: CGFloat = 0.8) {
//        if let kern = kern {
//            let str = NSString(format: "%@", text)
//            let attributedString = NSMutableAttributedString(string: text)
//            attributedString.addAttributes([.kern: kern, .font: self.font ?? UIFont.regularLocalizedFont(ofSize: 14),
//                                            .foregroundColor: self.textColor ?? UIColor.SsoldotTheme.dark],
//                                           range: NSRange(location: 0, length: str.length))
//            if isLine {
//                let style = NSMutableParagraphStyle()
//                style.lineHeightMultiple = lineHeightMultiple
//                attributedString.addAttribute(.paragraphStyle, value: style,
//                                              range: NSRange(location: 0, length: str.length))
//            }
//            self.attributedText = attributedString
//        } else {
//            self.text = text
//        }
    }

    func setHtmlText(_ text: String, kern: CGFloat? = nil, isLine: Bool = false, lineHeightMultiple: CGFloat = 0.8) {
        do {
            let result: String = text
            self.attributedText = try NSMutableAttributedString(htmlString: result)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    // 텍스트 지정 후 반환
    func withText(_ text: String, kern: CGFloat? = nil, isLine: Bool = false) -> UILabel {
        self.setText(text, kern: kern, isLine: isLine)
        return self
    }

    func withUnderlineText(_ title: String, kern: CGFloat = 1.0) -> UILabel {
        self.setUnderlineText(title, kern: kern)
        return self
    }

    func setUnderlineText(_ title: String, partition: String = "과 ", kern: CGFloat = 1.0) {
//        let separate = ViewUtility.getPrevAndNextString(title, partition: partition)
//        let font = self.font ?? UIFont.regularLocalizedFont(ofSize: 12)
//        let color = self.textColor ?? UIColor.black
//
//        let attributeText = NSMutableAttributedString()
//
//        let prevText = NSMutableAttributedString(string: separate.0)
//        let prevRange = NSRange(location: 0, length: prevText.length)
//        prevText.addAttributes([.underlineStyle: NSUnderlineStyle.single.rawValue, .kern: kern,
//                                .font: font, .foregroundColor: color], range: prevRange)
//        attributeText.append(prevText)
//        if separate.1 != "" {
//            let partitionText = NSMutableAttributedString(string: partition)
//            let partitionRange = NSRange(location: 0, length: partitionText.length)
//            partitionText.addAttributes([.font: font, .kern: kern, .foregroundColor: color], range: partitionRange)
//            attributeText.append(partitionText)
//
//            let nextText = NSMutableAttributedString(string: separate.1)
//            let nextRange = NSRange(location: 0, length: nextText.length)
//            nextText.addAttributes([.underlineStyle: NSUnderlineStyle.single.rawValue, .font: font, .kern: kern,
//                                    .foregroundColor: color], range: nextRange)
//            attributeText.append(nextText)
//        }
//
//        self.attributedText = attributeText
    }

    // attributedString 지정 후 반환
    func withAttributedText(_ attributedText: NSMutableAttributedString) -> UILabel {
        self.attributedText = attributedText
        return self
    }

    // 텍스트 alignment 지정 후 반환
    func withTextAlignment(_ textAlignment: NSTextAlignment) -> UILabel {
        setTextAlignment(textAlignment)
        return self
    }

    func setTextAlignment(_ textAlignment: NSTextAlignment) {
        self.textAlignment = textAlignment
    }

    // 텍스트 줄간격 설정 후 반환
    func withLineSpacing(_ text: String, lineSpacing: CGFloat, textAlignment: NSTextAlignment = .left) -> UILabel {
        let nsString = NSString(format: "%@", text)
        let attrString = NSMutableAttributedString(string: text)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.alignment = textAlignment
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style,
                                range: NSRange(location: 0, length: nsString.length))
        self.attributedText = attrString
        return self
    }

    // 글자 최소 크기 설정
    func setMinimumScaleFontToWidth(_ scale: CGFloat) {
        self.adjustsFontSizeToFitWidth = true
        self.minimumScaleFactor = scale
    }

    // 글자 최소 크기 설정 후 반환 (비율)
    func withMinimumScaleFontToWidth(_ scale: CGFloat) -> UILabel {
        setMinimumScaleFontToWidth(scale)
        return self
    }

    // 상단 border 설정 후 반환
    override func withTopBorder(color: UIColor, borderWidth: CGFloat = 1) -> UILabel {
        addTopBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // 하단 border 설정 후 반환
    override func withBottomBorder(color: UIColor,
                                   borderWidth: CGFloat = 1) -> UILabel {
        addBottomBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // border 설정 후 반환
    override func withBorder(color: UIColor, borderWidth: CGFloat = 1) -> UILabel {
        addBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // radius 설정 후 반환
    override func withLayerCornerRadius(_ cornerRadius: CGFloat) -> UILabel {
        self.layer.cornerRadius = cornerRadius
        return self
    }

    func addTextSpacing(_ letterSpacing: CGFloat) {
        if let labelText = text, labelText.count > 0 {
            let nsString = NSString(format: "%@", labelText)
            let attributedString = NSMutableAttributedString(string: labelText)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: letterSpacing,
                                          range: NSRange(location: 0, length: nsString.length))
            attributedText = attributedString
        }
    }

    func withTextSpacing(_ letterSpacing: CGFloat) -> UILabel {
        if let labelText = text, labelText.count > 0 {
            let nsString = NSString(format: "%@", labelText)
            let attributedString = NSMutableAttributedString(string: labelText)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: letterSpacing,
                                          range: NSRange(location: 0, length: nsString.length))
            attributedText = attributedString
        }
        return self
    }

    func getTextHeight(width: CGFloat) -> CGFloat {
        if let attributedText = self.attributedText {
            return attributedText.boundingRect(with: CGSize(width: width, height: 10000),
                                               options: [.usesLineFragmentOrigin, .usesFontLeading, .usesDeviceMetrics],
                                               context: nil).height
        }
        return 0
    }
}

class CopyableLabel: UILabel {
    var fullUrl: String?
    override public var canBecomeFirstResponder: Bool {
        return true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    func sharedInit() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer( target: self, action: #selector(showMenu(sender:))))
    }

    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = fullUrl ?? text
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    @objc func showMenu(sender: Any?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(copy(_:)))
    }
}
