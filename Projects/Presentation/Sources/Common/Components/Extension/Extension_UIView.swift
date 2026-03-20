import UIKit

// view 기능 확장
extension UIView {

    private enum Border: Int {
        case top, bottom, left, right
    }

    // 배경색 지정하며 view 생성
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
    }

    // 좌측 border 생성
    func addLeftBorder(color: UIColor, borderWidth: CGFloat = 1,
                       borderLength: CGFloat? = nil) {
        let leftBorderView = UIView(backgroundColor: color)
        leftBorderView.tag = Border.left.rawValue + 100
        addSubview(leftBorderView)

        leftBorderView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(borderLength ?? self)
            make.left.equalTo(self)
            make.width.equalTo(borderWidth)
        }
    }

    // 우측 border 생성
    func addRightBorder(color: UIColor, borderWidth: CGFloat = 1,
                        borderLength: CGFloat? = nil) {
        let rightBorderView = UIView(backgroundColor: color)
        rightBorderView.tag = Border.right.rawValue + 100
        addSubview(rightBorderView)

        rightBorderView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(borderLength ?? self)
            make.right.equalTo(self)
            make.width.equalTo(borderWidth)
        }
    }

    // 상단 border 생성
    func addTopBorder(color: UIColor, borderWidth: CGFloat = 1,
                      borderLength: CGFloat? = nil) {
        let topBorderView = UIView(backgroundColor: color)
        topBorderView.tag = Border.top.rawValue + 100
        addSubview(topBorderView)

        topBorderView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.width.equalTo(borderLength ?? self)
            make.top.equalTo(self)
            make.height.equalTo(borderWidth)
        }
    }

    // 하단 border 생성
    func addBottomBorder(color: UIColor, borderWidth: CGFloat = 1,
                         borderLength: CGFloat? = nil) {
        let bottomBorderView = UIView(backgroundColor: color)
        bottomBorderView.tag = Border.bottom.rawValue + 100
        addSubview(bottomBorderView)

        bottomBorderView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.width.equalTo(borderLength ?? self)
            make.bottom.equalTo(self)
            make.height.equalTo(borderWidth)
        }
    }

    // 하단 border 삭제
    func removeBottomBorder() {
        while let viewWithTag = self.viewWithTag(Border.bottom.rawValue + 100) {
            viewWithTag.removeFromSuperview()
        }
    }

    // 좌측 border 삭제
    func removeLeftBorder() {
        while let viewWithTag = self.viewWithTag(Border.left.rawValue + 100) {
            viewWithTag.removeFromSuperview()
        }
    }

    // 우측 border 삭제
    func removeRightBorder() {
        while let viewWithTag = self.viewWithTag(Border.right.rawValue + 100) {
            viewWithTag.removeFromSuperview()
        }
    }

     // 상단 border 삭제
    func removeTopBorder() {
        while let viewWithTag = self.viewWithTag(Border.top.rawValue + 100) {
            viewWithTag.removeFromSuperview()
        }
    }

    // border 생성
    func addBorder(color: UIColor, borderWidth: CGFloat = 1) {
        layer.borderColor = color.cgColor
        layer.borderWidth = borderWidth
    }

    // border 삭제
    func removeBorder() {
        layer.borderColor = UIColor.clear.cgColor
        layer.borderWidth = 0
    }

    // shadow 생성
    func addShadow(color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
    }

    // 뷰의 내부로 shadow 생성
    func addInnerShadow(edges: [Edge], shadowRadius radius: CGFloat = 5.0,
                        toColor: UIColor = UIColor.Theme.white,
                        fromColor: UIColor = UIColor("#E7E7E7", alpha: 0.2)) {
        for edge in edges {
            let shadow = EdgeShadowLayer(forView: self, edge: edge, shadowRadius: radius,
                                         toColor: toColor, fromColor: fromColor)
            self.layer.addSublayer(shadow)
        }
    }

    // 내부 shadow 삭제
    func removeInnerShadow() {
        if let sublayers = self.layer.sublayers {
            for sublayer in sublayers {
                if let innerShadow = sublayer as? EdgeShadowLayer {
                    innerShadow.removeFromSuperlayer()
                }
            }
        }
    }

    // gradient 배경 적용
    func applyGradient(_ color: [UIColor]) {
        self.applyGradient(color, locations: nil)
    }

    func applyGradient(_ color: [UIColor], locations: [NSNumber]?, radius: CGFloat = 0.0) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.cornerRadius = radius
        gradient.frame = self.bounds
        gradient.colors = color.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }

    // 여기부터 chaining 함수 (override 의 경우 view의 chaining 함수 override)
    // border 생성 후 반환
    @objc func withBorder(color: UIColor,
                          borderWidth: CGFloat = 1) -> UIView {
        addBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // 상단 border 생성 후 반환
    @objc func withTopBorder(color: UIColor,
                             borderWidth: CGFloat = 1) -> UIView {
        addTopBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // 하단 border 생성 후 반환
    @objc func withBottomBorder(color: UIColor,
                                borderWidth: CGFloat = 1) -> UIView {
        addBottomBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // 좌측 border 생성 후 반환
    @objc func withLeftBorder(color: UIColor,
                              borderWidth: CGFloat = 1) -> UIView {
        addLeftBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // 우측 border 생성 후 반환
    @objc func withRightBorder(color: UIColor,
                               borderWidth: CGFloat = 1) -> UIView {
        addRightBorder(color: color, borderWidth: borderWidth)
        return self
    }

    // shadow 적용 후 반환
    @objc func withShadow(color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) -> UIView {
        addShadow(color: color, opacity: opacity, offset: offset, radius: radius)
        return self
    }

    // 뷰 내부에 레이블 생성 후 반환
    func withLabel(_ label: UILabel, leftMargin: CGFloat, topMargin: CGFloat) -> UIView {
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.equalTo(self).offset(leftMargin)
            make.top.equalTo(self).offset(topMargin)
        }

        return self
    }

    // 뷰 내부에 세로로 가운데 위치한 레이블 생성 후 반환
    func withVerticalCenterLabel(_ label: UILabel, leftMargin: CGFloat) -> UIView {
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.left.equalTo(self).offset(leftMargin)
            make.centerY.equalTo(self)
        }

        return self
    }

    // 뷰 내부에 가로로 가운데 위치한 레이블 생성 후 반환
    func withHorizontalCenterLabel(_ label: UILabel, topMargin: CGFloat) -> UIView {
        self.addSubview(label)

        label.snp.makeConstraints { make in
            make.top.equalTo(self).offset(topMargin)
            make.centerX.equalTo(self)
        }

        return self
    }

    // 뷰 내부에 이미지 생성 후 반환(이미지의 중심으로 부터 왼쪽 마진을 계산)
    func withImage(_ imageView: UIImageView, leftMargin: CGFloat, topMargin: CGFloat) -> UIView {
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.centerX.equalTo(self.snp.left).offset(leftMargin)
            make.top.equalTo(self).offset(topMargin)
        }

        return self
    }

    // 뷰 내부에 이미지 생성 후 반환(세로로 가운데 위치, 왼쪽부터 왼쪽마진 계산)
    func withVerticalCenterImage(_ imageView: UIImageView, leftMargin: CGFloat) -> UIView {
        self.addSubview(imageView)

        imageView.snp.makeConstraints { make in
            make.left.equalTo(self).offset(leftMargin)
            make.centerY.equalTo(self)
        }

        return self
    }

    func setBlur(style: UIBlurEffect.Style) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.tintColor = UIColor.white
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 900
        addSubview(blurEffectView)
    }

    func removeBlur() {
        while let viewWithTag = self.viewWithTag(900) {
            viewWithTag.removeFromSuperview()
        }
    }

    func withBlur(style: UIBlurEffect.Style) -> UIView {
        setBlur(style: style)
        return self
    }

    // radius 설정 후 반환
    @objc func withLayerCornerRadius(_ cornerRadius: CGFloat) -> UIView {
        self.layer.cornerRadius = cornerRadius
        return self
    }

    func rotate(_ angle: CGFloat) {
        self.transform = CGAffineTransform(rotationAngle: CGFloat.pi / (180 / angle))
    }
}

enum Edge {
    case top
    case left
    case bottom
    case right
}

// gradient 설정 객체
fileprivate final class EdgeShadowLayer: CAGradientLayer {

    init(forView view: UIView, edge: Edge, shadowRadius radius: CGFloat = 5.0,
         toColor: UIColor = UIColor.Theme.white,
         fromColor: UIColor = UIColor("#E7E7E7", alpha: 0.2)) {
        super.init()
        self.colors = [fromColor.cgColor, toColor.cgColor]
        self.shadowRadius = radius

        let viewFrame = view.frame

        switch edge {
        case .top:
            startPoint = CGPoint(x: 0.5, y: 0.0)
            endPoint = CGPoint(x: 0.5, y: 1.0)
            self.frame = CGRect(x: 0.0, y: 0.0, width: viewFrame.width, height: shadowRadius)
        case .bottom:
            startPoint = CGPoint(x: 0.5, y: 1.0)
            endPoint = CGPoint(x: 0.5, y: 0.0)
            self.frame = CGRect(x: 0.0, y: viewFrame.height - shadowRadius,
                                width: viewFrame.width, height: shadowRadius)
        case .left:
            startPoint = CGPoint(x: 0.0, y: 0.5)
            endPoint = CGPoint(x: 1.0, y: 0.5)
            self.frame = CGRect(x: 0.0, y: 0.0, width: shadowRadius, height: viewFrame.height)
        case .right:
            startPoint = CGPoint(x: 1.0, y: 0.5)
            endPoint = CGPoint(x: 0.0, y: 0.5)
            self.frame = CGRect(x: viewFrame.width - shadowRadius, y: 0.0,
                                width: shadowRadius, height: viewFrame.height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("EdgeShadowLayer does not support NSCoding.")
    }
}
