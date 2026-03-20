import UIKit

extension UITextView {
    func setHeightToFit() {
        self.sizeToFit()
        self.isScrollEnabled = false
    }

    func setZeroMargin() {
        self.textContainer.lineFragmentPadding = 0
        self.textContainerInset = UIEdgeInsets.zero
        self.contentInset = UIEdgeInsets.zero
    }

    func setDataDetectorTypes(_ dataDetectorTypes: UIDataDetectorTypes) {
        self.dataDetectorTypes = dataDetectorTypes
    }

    func setText(_ text: String, kern: CGFloat? = nil, isLine: Bool = false, lineHeightMultiple: CGFloat = 0.8) {
        if let kern = kern, let font = self.font, let textColor = self.textColor {
            let nsString = NSString(format: "%@", text)
            let attributedString = NSMutableAttributedString(string: text)
            attributedString.addAttributes([.kern: kern, .font: font, .foregroundColor: textColor],
                                           range: NSRange(location: 0, length: nsString.length))
            if isLine {
                let style = NSMutableParagraphStyle()
                style.lineHeightMultiple = lineHeightMultiple
                attributedString.addAttribute(.paragraphStyle, value: style,
                                              range: NSRange(location: 0, length: nsString.length))
            }
            self.attributedText = attributedString
        } else {
            self.text = text
        }
    }

    func withHeightToFit() -> UITextView {
        setHeightToFit()
        return self
    }

    func withZeroMargin() -> UITextView {
        setZeroMargin()
        return self
    }

    func withDataDetectorTypes(_ dataDetectorTypes: UIDataDetectorTypes) -> UITextView {
        setDataDetectorTypes(dataDetectorTypes)
        return self
    }

    func withText(_ text: String, kern: CGFloat? = nil, isLine: Bool = false,
                  lineHeightMultiple: CGFloat = 0.8) -> UITextView {
        self.setText(text, kern: kern, isLine: isLine, lineHeightMultiple: lineHeightMultiple)
        return self
    }

    // 여기부터 chaining 함수 (override 의 경우 view의 chaining 함수 override)
    // 입력 폰트 지정 후 반환
    func withFont(_ font: UIFont) -> UITextView {
        self.font = font
        return self
    }

    // 입력 텍스트 색 지정 후 반환
    func withTextColor(_ textColor: UIColor) -> UITextView {
        self.textColor = textColor
        return self
    }

    // 입력 커서 색 변경 후 반환
    func withTintColor(_ tintColor: UIColor) -> UITextView {
        self.tintColor = tintColor
        return self
    }

    // 텍스트 자동완성 타입 지정 후 반환
    func withAutocapitalizationType(_ autocapitalizationType: UITextAutocapitalizationType) -> UITextView {
        self.autocapitalizationType = autocapitalizationType
        return self
    }

    // 키보드 타입 지정 후 반환
    func withKeyboardType(_ keyboardType: UIKeyboardType) -> UITextView {
        self.keyboardType = keyboardType
        return self
    }

    // 리턴키 타입 지정 후 반환
    func withReturnKeyType(_ returnKeyType: UIReturnKeyType) -> UITextView {
        self.returnKeyType = returnKeyType
        return self
    }

    // 입력 텍스트 alignment 지정 후 반환
    func withTextAlignment(_ textAlignment: NSTextAlignment) -> UITextView {
        self.textAlignment = textAlignment
        return self
    }

    // 배경 색 지정 후 반환
    func withBackgroundColor(_ backgroundColor: UIColor) -> UITextView {
        self.backgroundColor = backgroundColor
        return self
    }

    // radius 값 지정 후 반환
    func withCornerRadius(_ cornerRadius: CGFloat) -> UITextView {
        self.layer.cornerRadius = cornerRadius
        return self
    }

    // 상단 border 설정 후 반환
    func withTopBorder(color: UIColor, borderWidth: CGFloat = 1,
                       borderLength: CGFloat? = nil) -> UITextView {
        addTopBorder(color: color, borderWidth: borderWidth, borderLength: borderLength)
        return self
    }

    // 하단 border 설정 후 반환
    override func withBottomBorder(color: UIColor,
                                   borderWidth: CGFloat = 1) -> UITextView {
        addBottomBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // border 설정 후 반환
    override func withBorder(color: UIColor, borderWidth: CGFloat = 1) -> UITextView {
        addBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // 입력자 자동 고침 타입 지정 후 반환
    func withAutoCorrectType(_ autocorrectionType: UITextAutocorrectionType) -> UITextView {
        self.autocorrectionType = autocorrectionType
        return self
    }

    // 태그 입력 후 반환
    func withTag(_ tag: Int) -> UITextView {
        self.tag = tag
        return self
    }

    // 수정 가능 여부 설정 후 반환
    func withEditable(_ isEditable: Bool) -> UITextView {
        self.isEditable = isEditable
        return self
    }

    func withKeyboardAppearance(_ keyboardAppearance: UIKeyboardAppearance) -> UITextView {
        self.keyboardAppearance = keyboardAppearance
        return self
    }

    func getTextHeight(width: CGFloat) -> CGFloat {
        if let attributedText = self.attributedText {
            return attributedText.boundingRect(with: CGSize(width: width, height: 10000),
                                               options: [.usesLineFragmentOrigin, .usesFontLeading],
                                               context: nil).height
        }
        return 0
    }

    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}
