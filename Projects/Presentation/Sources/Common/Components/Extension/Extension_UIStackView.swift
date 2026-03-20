import UIKit

// StackView 기능 확장
extension UIStackView {

    // 여기부터 chaining 함수 (override 의 경우 view의 chaining 함수 override)
    // axis 값 지정 후 반환 (.vertical, .horizontal)
    func withAxis(_ axis: NSLayoutConstraint.Axis) -> UIStackView {
        self.axis = axis
        return self
    }

    // 간격(spacing) 지정 후 반환
    func withSpacing(_ spacing: CGFloat) -> UIStackView {
        self.spacing = spacing
        return self
    }

    // distribution 지정 후 반환
    func withDistribution(_ distribution: UIStackView.Distribution) -> UIStackView {
        self.distribution = distribution
        return self
    }

    // alignment 지정 후 반환
    func withAlignment(_ alignment: UIStackView.Alignment) -> UIStackView {
        self.alignment = alignment
        return self
    }
}
