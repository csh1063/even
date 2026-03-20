import UIKit

// TextField 기능 확장
extension UITextField {

    // 여기부터 chaining 함수 (override 의 경우 view의 chaining 함수 override)
    // 입력 폰트 지정 후 반환
    func withFont(_ font: UIFont) -> UITextField {
        self.font = font
        return self
    }

    // placeholder 입력 후 반환
    func withPlaceholder(_ placeholder: String) -> UITextField {
        self.placeholder = placeholder
        return self
    }

    // 입력 텍스트 색 지정 후 반환
    func withTextColor(_ textColor: UIColor) -> UITextField {
        self.textColor = textColor
        return self
    }

    // 입력 커서 색 변경 후 반환
    func withTintColor(_ tintColor: UIColor) -> UITextField {
        self.tintColor = tintColor
        return self
    }

    // 텍스트 자동완성 타입 지정 후 반환
    func withAutocapitalizationType(_ autocapitalizationType: UITextAutocapitalizationType) -> UITextField {
        self.autocapitalizationType = autocapitalizationType
        return self
    }

    // 키보드 타입 지정 후 반환
    func withKeyboardType(_ keyboardType: UIKeyboardType) -> UITextField {
        self.keyboardType = keyboardType
        return self
    }

    // 리턴키 타입 지정 후 반환
    func withReturnKeyType(_ returnKeyType: UIReturnKeyType) -> UITextField {
        self.returnKeyType = returnKeyType
        return self
    }

    // 입력 텍스트 alignment 지정 후 반환
    func withTextAlignment(_ textAlignment: NSTextAlignment) -> UITextField {
        self.textAlignment = textAlignment
        return self
    }

    // attributed placeholder 입력 후 반환
    func withAttributedPlaceholder(_ attributedPlaceholder: NSAttributedString) -> UITextField {
        self.attributedPlaceholder = attributedPlaceholder
        return self
    }

    // 배경 색 지정 후 반환
    func withBackgroundColor(_ backgroundColor: UIColor) -> UITextField {
        self.backgroundColor = backgroundColor
        return self
    }

    // 입력 창과 입력 텍스트 사이 왼쪽 간격 지정 후 반환
    func withLeftMargin(_ margin: CGFloat) -> UITextField {
        self.leftViewMode = .always
        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: margin, height: margin))
        return self
    }

    // 입력 창과 입력 텍스트 사이 오른쪽 간격 지정 후 반환
    func withRightMargin(_ margin: CGFloat) -> UITextField {
        self.rightViewMode = .always
        self.rightView = UIView(frame: CGRect(x: 0, y: 0, width: margin, height: margin))
        return self
    }

    // radius 값 지정 후 반환
    func withCornerRadius(_ cornerRadius: CGFloat) -> UITextField {
        self.layer.cornerRadius = cornerRadius
        return self
    }

    // 상단 border 설정 후 반환
    func withTopBorder(color: UIColor, borderWidth: CGFloat = 1,
                       borderLength: CGFloat? = nil) -> UITextField {
        addTopBorder(color: color, borderWidth: borderWidth, borderLength: borderLength)
        return self
    }

    // 하단 border 설정 후 반환
    override func withBottomBorder(color: UIColor,
                                   borderWidth: CGFloat = 1) -> UITextField {
        addBottomBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // border 설정 후 반환
    override func withBorder(color: UIColor, borderWidth: CGFloat = 1) -> UITextField {
        addBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // 입력자 자동 고침 타입 지정 후 반환
    func withAutoCorrectType(_ autocorrectionType: UITextAutocorrectionType) -> UITextField {
        self.autocorrectionType = autocorrectionType
        return self
    }

    // 태그 입력 후 반환
    func withTag(_ tag: Int) -> UITextField {
        self.tag = tag
        return self
    }

    // 수정 가능 여부 설정 후 반환
    func withEditable(_ isEditable: Bool) -> UITextField {
        self.isEnabled = false
        return self
    }

    func withKeyboardAppearance(_ keyboardAppearance: UIKeyboardAppearance) -> UITextField {
        self.keyboardAppearance = keyboardAppearance
        return self
    }
}
