//
//  CustomTabBarViewController.swift
//  RxTest
//
//  Created by sanghyeon on 6/27/24.
//

import Foundation
import UIKit

public enum CustomTabBarAlign {
    case center
    case left
    case right
}

open class CustomTabBarController: UIViewController {

    public struct Margin {
        let leading: CGFloat
        let trailing: CGFloat
        let bottom: CGFloat

        static var zero: Margin {
            return Margin()
        }
        
        init(leading: CGFloat = 0, trailing: CGFloat = 0, bottom: CGFloat = 0) {
            self.leading = leading
            self.trailing = trailing
            self.bottom = bottom
        }
    }

    public struct Padding {
        let leading: CGFloat
        let trailing: CGFloat

        static var zero: Padding {
            return Padding(leading: 0, trailing: 0)
        }
    }

    private var tabBarView = UIView()
    private var tabBarLeading: NSLayoutConstraint!
    private var tabBarTrailing: NSLayoutConstraint!
    private var tabBarCenter: NSLayoutConstraint!
    private var tabBarBottom: NSLayoutConstraint!
    private var tabBarHeight: NSLayoutConstraint!
    private var tabBarWidth: NSLayoutConstraint!
    private var tabBarPaddingLeading: NSLayoutConstraint!
    private var tabBarPaddingTrailing: NSLayoutConstraint!

    private var tabBarCoverView = UIView()
    private var tabBarShadowView = UIView()

    private var tabBarStackView = UIStackView()

    private var selectedBox: UIView?
    private var selectedBoxLeading: NSLayoutConstraint?
    private var selectedBoxTrailing: NSLayoutConstraint?
    private var isFirst: Bool = true

    private var viewControllers: [UIViewController] = []
    private var items: [CustomTabBarItem] = []
    private var previewsIndex = 0

    private var margin: Margin = .zero
    private var padding: Padding = .zero
    private var height: CGFloat = 50
    private var itemWidth: CGFloat?
    private var cornerRadius: CGFloat?

    private var color: UIColor = .black
    private var alpha: Float = 0
    private var x: CGFloat = 0
    private var y: CGFloat = 0
    private var blur: CGFloat = 0

    public var selectedIndex = 0 {
        willSet {
            previewsIndex = selectedIndex
        }
        didSet {
            updateView()
        }
    }

    private var titleColor: UIColor = .gray
    private var selectedTitleColor: UIColor = .black

    private var tabbarBackgroundColor: UIColor = .systemBackground {
        didSet {
            self.tabBarView.backgroundColor = tabbarBackgroundColor
            self.tabBarCoverView.backgroundColor = tabbarBackgroundColor.withAlphaComponent(1.0)
            self.tabBarShadowView.backgroundColor = tabbarBackgroundColor
        }
    }

    weak var delegate: CustomTabBarDelegate?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        //        super.init(nibName: "CustomTabBarViewController", bundle: nil)
        super.init(nibName: nil, bundle: nil)

    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.initView()
        self.setupButtons()
        self.setMargin()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        self.updateView()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tabBarShadowView.layer.masksToBounds = false
        self.tabBarShadowView.layer.shadowColor = color.cgColor
        self.tabBarShadowView.layer.shadowOpacity = alpha
        self.tabBarShadowView.layer.shadowOffset = CGSize(width: x, height: y)
        self.tabBarShadowView.layer.shadowRadius = blur / UIScreen.main.scale
        self.tabBarShadowView.layer.shadowPath = nil
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc private func tabButtonTapped(_ sender: UIButton) {
        self.selectedIndex = sender.tag
    }

    private func initView() {

        self.tabBarCoverView.isHidden = true
        self.tabBarCoverView.backgroundColor = self.tabbarBackgroundColor.withAlphaComponent(1.0)
        self.tabBarCoverView.translatesAutoresizingMaskIntoConstraints = false
        self.tabBarView.backgroundColor = self.tabbarBackgroundColor
        self.tabBarView.translatesAutoresizingMaskIntoConstraints = false

        self.tabBarShadowView.backgroundColor = self.tabbarBackgroundColor
        self.tabBarShadowView.translatesAutoresizingMaskIntoConstraints = false

        self.tabBarStackView.distribution = .fillEqually
        self.tabBarStackView.axis = .horizontal
        self.tabBarStackView.alignment = .center
        self.tabBarStackView.spacing = 0
        self.tabBarStackView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(tabBarShadowView)
        self.view.addSubview(tabBarCoverView)
        self.view.addSubview(tabBarView)
        self.tabBarView.addSubview(tabBarStackView)

        self.tabBarCenter = self.tabBarView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        self.tabBarLeading = self.tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin.leading)
        self.tabBarTrailing = self.tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: margin.trailing)
        self.tabBarBottom = self.tabBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: margin.bottom)
        self.tabBarHeight = self.tabBarView.heightAnchor.constraint(equalToConstant: height)
        self.tabBarWidth = self.tabBarView.widthAnchor.constraint(equalToConstant: (itemWidth ?? 70) * CGFloat(items.count))

        self.tabBarPaddingLeading = self.tabBarStackView.leadingAnchor.constraint(
            equalTo: self.tabBarView.leadingAnchor,
            constant: padding.leading)
        self.tabBarPaddingTrailing = self.tabBarStackView.trailingAnchor.constraint(
            equalTo: self.tabBarView.trailingAnchor,
            constant: -padding.trailing)

        NSLayoutConstraint.activate([
            self.tabBarLeading,
            self.tabBarTrailing,
            self.tabBarBottom,
            self.tabBarHeight,
            self.tabBarStackView.topAnchor.constraint(equalTo: self.tabBarView.topAnchor),
            self.tabBarStackView.bottomAnchor.constraint(equalTo: self.tabBarView.bottomAnchor),
            self.tabBarPaddingLeading,
            self.tabBarPaddingTrailing,
            self.tabBarCoverView.topAnchor.constraint(equalTo: self.tabBarView.topAnchor),
            self.tabBarCoverView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.tabBarCoverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.tabBarCoverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.tabBarShadowView.topAnchor.constraint(equalTo: self.tabBarView.topAnchor),
            self.tabBarShadowView.bottomAnchor.constraint(equalTo: self.tabBarView.bottomAnchor),
            self.tabBarShadowView.leadingAnchor.constraint(equalTo: self.tabBarView.leadingAnchor),
            self.tabBarShadowView.trailingAnchor.constraint(equalTo: self.tabBarView.trailingAnchor)
        ])
    }

    private func setupButtons() {

        guard self.tabBarStackView.arrangedSubviews.isEmpty else {
            return
        }

        for (index, viewController) in viewControllers.enumerated() {

            let item = CustomTabBarItem()
            item.titleColor = self.titleColor
            item.selectedTitleColor = self.selectedTitleColor
            item.setTag(index)
            item.setItem(viewController.tabBarItem)
            item.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
//            if let itemWidth {
//                item.widthAnchor.constraint(equalToConstant: itemWidth).isActive = true
//            }

            self.tabBarStackView.addArrangedSubview(item)
            items.append(item)
        }
    }

    private func updateView() {

        guard viewControllers.count > previewsIndex else {return}

        let previousVC = viewControllers[previewsIndex]

        if delegate == nil || delegate?.tabBarController(self, shouldSelect: previousVC) == true {
            previousVC.willMove(toParent: nil)
            previousVC.view.removeFromSuperview()
            previousVC.removeFromParent()

            let selectedVC = viewControllers[selectedIndex]
            self.addChild(selectedVC)
            view.insertSubview(selectedVC.view, at: 0)

            selectedVC.view.frame = view.bounds
            selectedVC.view.layoutIfNeeded()
            selectedVC.didMove(toParent: self)

            self.delegate?.tabBarController(self, didSelect: selectedVC)

            self.items.forEach { $0.isSelected = ($0.tag == selectedIndex) }

            if let box = self.selectedBox {
                if self.items.count > selectedIndex {
                    let item = self.items[selectedIndex]

                    selectedBoxLeading?.isActive = false
                    selectedBoxTrailing?.isActive = false

                    let leading = box.leadingAnchor.constraint(equalTo: item.leadingAnchor, constant: 8)
                    let trailing = box.trailingAnchor.constraint(equalTo: item.trailingAnchor, constant: -8)
                    NSLayoutConstraint.activate([leading, trailing])
                    self.selectedBoxLeading = leading
                    self.selectedBoxTrailing = trailing

                    if isFirst {
                        self.view.layoutIfNeeded()
                        self.isFirst = false
                    } else {
                        UIView.animate(withDuration: 0.3) {
                            self.view.layoutIfNeeded()
                        }
                    }
                }
            }
        }
    }

    private func setMargin() {

        self.tabBarHeight.constant = self.height
        self.tabBarBottom.constant = -self.margin.bottom
        self.tabBarLeading.constant = self.margin.leading
        self.tabBarTrailing.constant = -self.margin.trailing

        self.tabBarPaddingLeading.constant = self.padding.leading
        self.tabBarPaddingTrailing.constant = -self.padding.trailing

        if let cornerRadius = self.cornerRadius {
            self.tabBarView.layer.cornerRadius = cornerRadius
            self.tabBarView.layer.masksToBounds = true

            self.tabBarShadowView.layer.cornerRadius = cornerRadius
        }

        self.view.layoutIfNeeded()
    }

    // MARK: Public
    public func setViewControllers(_ viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
    }

    public func setBackgroundColor(_ color: UIColor) {
        self.tabbarBackgroundColor = color
    }

    public func setItemColors(normal titleColor: UIColor? = nil,
                              selected selectedTitleColor: UIColor? = nil) {

        if let titleColor = titleColor {
            self.titleColor = titleColor
            self.selectedTitleColor = selectedTitleColor ?? titleColor

            for subview in self.tabBarStackView.arrangedSubviews {
                if let view = subview as? CustomTabBarItem {
                    view.titleColor = titleColor
                    view.selectedTitleColor = selectedTitleColor ?? titleColor
                }
            }
        }
    }
    
    public func setAlign(_ align: CustomTabBarAlign = CustomTabBarAlign.center) {
        switch align {
        case .center:
            self.tabBarCenter.isActive = true
            self.tabBarLeading.isActive = false
            self.tabBarTrailing.isActive = false
            self.tabBarWidth.isActive = true
        case .left:
            self.tabBarCenter.isActive = false
            self.tabBarLeading.isActive = true
            self.tabBarTrailing.isActive = false
            self.tabBarWidth.isActive = true
        case .right:
            self.tabBarCenter.isActive = false
            self.tabBarLeading.isActive = false
            self.tabBarTrailing.isActive = true
            self.tabBarWidth.isActive = true
        }
    }

    public func setLayoutMargin(height: CGFloat, itemWidth: CGFloat? = nil,
                                margin: Margin,
                                padding: Padding,
                                cornerRadius: CGFloat? = nil) {
        
        self.height = height
        self.itemWidth = itemWidth
        self.margin = margin
        self.padding = padding

        if margin.bottom == 0 {
            self.tabBarCoverView.isHidden = false
        } else {
            self.tabBarCoverView.isHidden = true
        }

        if let cornerRadius = cornerRadius {
            self.cornerRadius = cornerRadius
        }
        
        if let itemWidth {
            self.tabBarWidth.constant = itemWidth * CGFloat(items.count)
        }

        self.setMargin()
    }

    public func setShadow(color: UIColor,
                          alpha: Float,
                          x: CGFloat,
                          y: CGFloat,
                          blur: CGFloat) {

        self.color = color
        self.alpha = alpha
        self.x = x
        self.y = y
        self.blur = blur
    }

    public func setTabBarItem(_ image: String, selectedImage: String = "", vc: UIViewController, title: String? = nil) {
        let item = UITabBarItem()
        item.image = UIImage(systemName: image)
        item.selectedImage = UIImage(systemName: selectedImage) ?? UIImage(systemName: image)
        item.title = title
        vc.tabBarItem = item
    }

    public func animateBottom(isShow: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.tabBarBottom.constant = isShow ? self.margin.bottom:100
            self.view.layoutIfNeeded()
        }
    }

    public func animateFade(isShow: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.tabBarShadowView.alpha = isShow ? 1.0:0.0
            self.tabBarView.alpha = isShow ? 1.0:0.0
            self.tabBarCoverView.alpha = isShow ? 1.0:0.0
            self.view.layoutIfNeeded()
        }
    }

    public func setSelectedBox(color: UIColor) {
        let verticalMargin: CGFloat = 4
        let box = UIView()
        box.backgroundColor = color
        box.layer.cornerRadius = height / 2 - verticalMargin

        self.tabBarView.insertSubview(box, belowSubview: tabBarStackView)

        box.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            box.topAnchor.constraint(equalTo: self.tabBarView.topAnchor, constant: verticalMargin),
            box.bottomAnchor.constraint(equalTo: self.tabBarView.bottomAnchor, constant: -verticalMargin)
        ])

        self.selectedBox = box
    }
}
