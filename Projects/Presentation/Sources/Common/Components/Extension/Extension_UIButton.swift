import UIKit

// 버튼 기능 확장
extension UIButton {

    // The size of the image does not determine the the intrinsic size of the button.
    // 해당 이미지를 배경으로 하는 버튼 생성
    convenience init(backgroundImage image: UIImage) {
        self.init(frame: CGRect.zero)
        setBackgroundImage(image, for: .normal)
    }

    // 보통때와 선택했을때의 이미지를 설정하며 버튼 생성
    convenience init(normalBackgroundImage normalImage: UIImage, selectedBackgroundImage selectedImage: UIImage) {
        guard normalImage.size == selectedImage.size else {
            fatalError("The sizes of the images for normal and selected state differs.")
        }

        self.init(frame: CGRect.zero)
        setBackgroundImage(normalImage, for: .normal)
        setBackgroundImage(selectedImage, for: .selected)
    }

    // 보통때와 선택했을때의 배경색을 설정하며 버튼 생성
    // 이 경우 색에 해당하는 이미지를 만들어 적용하기 때문에 radius가 작동하지 않는다.
    convenience init(normalBackgroundColor normalColor: UIColor, selectedBackgroundColor selectedColor: UIColor) {
        self.init(frame: CGRect.zero)
        setBackgroundColor(normalColor, for: .normal)
        setBackgroundColor(selectedColor, for: .selected)
    }

    // 버튼 상태에 따른 배경이미지 지정
    // 이 경우 색에 해당하는 이미지를 만들어 적용하기 때문에 radius가 작동하지 않는다.
    func setBackgroundColor(_ backgroundColor: UIColor, for state: UIControl.State) {
        setBackgroundImage(UIImage.createImage(color: backgroundColor), for: state)
    }

    // 여기부터 chaining 함수 (override 의 경우 view의 chaining 함수 override)
    // 배경 색 지정 후 반환
    // 이 경우엔 배경색을 직접 지정하였기 때문에 다른 영향은 없다.
    func withBackgroundColor(_ backgroundColor: UIColor) -> UIButton {
        self.backgroundColor = backgroundColor
        return self
    }

    func withBackgroundImage(_ backgroundImage: UIImage?, for state: UIControl.State = .normal) -> UIButton {
        setBackgroundImage(backgroundImage, for: state)
        return self
    }

    // radius를 지정 후 반환
    override func withLayerCornerRadius(_ cornerRadius: CGFloat) -> UIButton {
        layer.cornerRadius = cornerRadius
        return self
    }

    // title 지정 후 반환
    func withTitle(_ title: String, for state: UIControl.State) -> UIButton {
        setTitle(title, for: state)
        return self
    }

    func withAttributedText(_ title: String, kern: CGFloat? = nil, for state: UIControl.State) -> UIButton {
        self.setAttributedText(title, kern: kern, for: state)
        return self
    }

    func setAttributedText(_ title: String, kern: CGFloat? = nil, for state: UIControl.State) {
        let font = self.titleLabel?.font ?? UIFont.regularLocalizedFont(ofSize: 12)
        let color = self.titleColor(for: state) ?? UIColor.black
        let attributeText = NSMutableAttributedString(string: title)
        let attributeRange = NSRange(location: 0, length: attributeText.length)
        var attributeOption: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        if let kern = kern {
            attributeOption[.kern] = kern
        }
        attributeText.addAttributes(attributeOption, range: attributeRange)

        setAttributedTitle(attributeText, for: state)
    }

//    func setUnderlineTitle(_ title: String, for state: UIControl.State) {
//        let partition = ", "
//        let separate = ViewUtility.getPrevAndNextString(title, partition: partition)
//        let font = self.titleLabel?.font ?? UIFont.regularLocalizedFont(ofSize: 12)
//        let color = self.titleColor(for: state) ?? UIColor.black
//
//        let attributeText = NSMutableAttributedString()
//
//        let prevText = NSMutableAttributedString(string: separate.0)
//        let prevRange = NSRange(location: 0, length: prevText.length)
//        prevText.addAttributes([.underlineStyle: NSUnderlineStyle.single.rawValue,
//                                .font: font,
//                                .foregroundColor: color], range: prevRange)
//        attributeText.append(prevText)
//        if separate.1 != "" {
//            let partitionText = NSMutableAttributedString(string: partition)
//            let partitionRange = NSRange(location: 0, length: partitionText.length)
//            partitionText.addAttributes([.font: font,
//                                         .foregroundColor: color], range: partitionRange)
//            attributeText.append(partitionText)
//
//            let nextText = NSMutableAttributedString(string: separate.1)
//            let nextRange = NSRange(location: 0, length: nextText.length)
//            nextText.addAttributes([.underlineStyle: NSUnderlineStyle.single.rawValue,
//                                    .font: font,
//                                    .foregroundColor: color], range: nextRange)
//            attributeText.append(nextText)
//        }
//
//        setAttributedTitle(attributeText, for: .normal)
//    }

//    func withUnderlineTitle(_ title: String, for state: UIControl.State) -> UIButton {
//        setUnderlineTitle(title, for: state)
//        return self
//    }

    // title color 지정 후 반환
    func withTitleColor(_ titleColor: UIColor, for state: UIControl.State) -> UIButton {
        setTitleColor(titleColor, for: state)
        return self
    }

    // title font 지정 후 반환
    func setTitleLabelFont(_ font: UIFont?) {
        titleLabel?.font = font
    }

    // title font 지정 후 반환
    func withTitleLabelFont(_ font: UIFont?) -> UIButton {
        setTitleLabelFont(font)
        return self
    }

    func isEnableAddedLabel(
        _ bool: Bool,
        enableTextColor: UIColor? = nil,
        disableTextColor: UIColor? = nil
    ) {
        for subview in subviews where subview.tag == 100 {
            if let label = subview as? UILabel {
                if bool {
                    if let enableTextColor {
                        label.textColor = enableTextColor
                    }
                } else {
                    if let disableTextColor {
                        label.textColor = disableTextColor
                    }
                }
            }
        }
    }

    func setNaviButtonForm(title: String, color: UIColor = UIColor.Theme.midnight,
                           image: UIImage, disabledImage: UIImage? = nil,
                           contentHorizontalAlignment: UIControl.ContentHorizontalAlignment = .left) {
        let label = UILabel().withText(title).withTextColor(color)
                             .withFont(UIFont.regularLocalizedFont(ofSize: 16))
        label.tag = 100
        addSubview(label)
        label.snp.makeConstraints { make in
            switch contentHorizontalAlignment {
            case .left:
                make.left.equalTo(self).offset(20)
                make.right.equalTo(self)
            case .right:
                make.left.equalTo(self)
                make.right.equalTo(self).offset(-20)
            default:
                make.left.equalTo(self)
                make.right.equalTo(self)
            }
            make.centerY.equalTo(self)
        }

        setImage(image, for: .normal)
        setImage(disabledImage, for: .disabled)

        self.contentHorizontalAlignment = contentHorizontalAlignment
    }

    func withNaviButtonForm(title: String, image: UIImage, disabledImage: UIImage? = nil,
                            contentHorizontalAlignment: UIControl.ContentHorizontalAlignment = .left) -> UIButton {
        setNaviButtonForm(title: title, image: image, disabledImage: disabledImage,
                          contentHorizontalAlignment: contentHorizontalAlignment)
        return self
    }

    func editNaviButtonForm(color: UIColor, image: UIImage, disabledImage: UIImage? = nil) {
        for subview in subviews {
            if let label = subview.viewWithTag(100) as? UILabel {
                label.setTextColor(color)
            }
        }

        setImage(image, for: .normal)
        setImage(disabledImage, for: .disabled)
    }

    func withContentAlignment(_ alignment: UIControl.ContentHorizontalAlignment) -> UIButton {
        contentHorizontalAlignment = alignment
        return self
    }

    // top border 설정 후 반환
    override func withTopBorder(color: UIColor, borderWidth: CGFloat = 1) -> UIButton {
        addTopBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // bottom border 설정 후 반환
    override func withBottomBorder(color: UIColor,
                                   borderWidth: CGFloat = 1) -> UIButton {
        addBottomBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // border 설정 후 반환
    override func withBorder(color: UIColor, borderWidth: CGFloat = 1) -> UIButton {
        addBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // shadow 설정 후 반환
    override func withShadow(color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) -> UIButton {
        addShadow(color: color, opacity: opacity, offset: offset, radius: radius)
        return self
    }

    // 이미지를 넣은 후 반환
    // 적용된 이미지의 경우 버튼 크기와 상관없이 자기 사이즈 유지
    func withImage(_ image: UIImage?, for state: UIControl.State = .normal,
                   contentMode: UIView.ContentMode = .center ) -> UIButton {
        self.setImage(image, for: state)
        self.contentMode = contentMode
        return self
    }

    func withSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) -> UIButton {
        self.semanticContentAttribute = semanticContentAttribute
        return self
    }

    func withTitleAlignment(_ alignment: NSTextAlignment) -> UIButton {
        self.titleLabel?.textAlignment = alignment
        return self
    }

    func withTitleWidth(_ width: CGFloat) -> UIButton {
        if let titleLabel = titleLabel {
            titleLabel.snp.makeConstraints { make in
                make.width.equalTo(width)
            }
        }
        return self
    }
}
