//
//  CustomTabBarViewController.swift
//  RxTest
//
//  Created by sanghyeon on 6/27/24.
//

import Foundation
import UIKit

open class CustomTabBarController: UIViewController {
    
    //    @IBOutlet var tabBarView: UIView!
    //    @IBOutlet var tabBarLeading: NSLayoutConstraint!
    //    @IBOutlet var tabBarTrailing: NSLayoutConstraint!
    //    @IBOutlet var tabBarBottom: NSLayoutConstraint!
    //    @IBOutlet var tabBarHeight: NSLayoutConstraint!
    //
    //    @IBOutlet var tabBarShadowView: UIView!
    //
    //    @IBOutlet var tabBarStackView: UIStackView!
    
    private var tabBarView: UIView = UIView()
    private var tabBarLeading: NSLayoutConstraint!
    private var tabBarTrailing: NSLayoutConstraint!
    private var tabBarBottom: NSLayoutConstraint!
    private var tabBarHeight: NSLayoutConstraint!
    
    private var tabBarShadowView: UIView = UIView()
    
    private var tabBarStackView: UIStackView = UIStackView()
    
    private var viewControllers: [UIViewController] = []
    private var items: [CustomTabBarItem] = []
    private var previewsIndex = 0
    
    private var leading: CGFloat = 0
    private var trailing: CGFloat = 0
    private var bottom: CGFloat = 0
    private var height: CGFloat = 50
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
    
    var titleColor: UIColor = .gray
    var selectedTitleColor: UIColor = .black
    
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
        print("==== \(Self.self) viewDidLoad        ====================")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("==== \(Self.self) viewWillAppear     ====================")
        
        self.setMargin()
        self.updateView()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("==== \(Self.self) viewDidAppear      ====================")
        
        self.tabBarShadowView.layer.masksToBounds = false
        self.tabBarShadowView.layer.shadowColor = color.cgColor
        self.tabBarShadowView.layer.shadowOpacity = alpha
        self.tabBarShadowView.layer.shadowOffset = CGSize(width: x, height: y)
        self.tabBarShadowView.layer.shadowRadius = blur / UIScreen.main.scale
        self.tabBarShadowView.layer.shadowPath = nil
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("==== \(Self.self) viewWillDisappear  ====================")
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("==== \(Self.self) viewDidDisappear   ====================")
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        self.selectedIndex = sender.tag
    }
    
    private func initView() {
        
        self.tabBarView.backgroundColor = .systemBackground
        self.tabBarView.translatesAutoresizingMaskIntoConstraints = false
        
        self.tabBarShadowView.backgroundColor = .systemBackground
        self.tabBarShadowView.translatesAutoresizingMaskIntoConstraints = false
        
        self.tabBarStackView.distribution = .fillEqually
        self.tabBarStackView.axis = .horizontal
        self.tabBarStackView.spacing = 0
        self.tabBarStackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(tabBarShadowView)
        self.view.addSubview(tabBarView)
        self.tabBarView.addSubview(tabBarStackView)
        
        self.tabBarLeading = self.tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leading)
        self.tabBarTrailing = self.tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: trailing)
        self.tabBarBottom = self.tabBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: bottom)
        self.tabBarHeight = self.tabBarView.heightAnchor.constraint(equalToConstant: height)
        
        NSLayoutConstraint.activate([
            self.tabBarLeading,
            self.tabBarTrailing,
            self.tabBarBottom,
            self.tabBarHeight,
            self.tabBarStackView.topAnchor.constraint(equalTo: self.tabBarView.topAnchor),
            self.tabBarStackView.bottomAnchor.constraint(equalTo: self.tabBarView.bottomAnchor),
            self.tabBarStackView.leadingAnchor.constraint(equalTo: self.tabBarView.leadingAnchor),
            self.tabBarStackView.trailingAnchor.constraint(equalTo: self.tabBarView.trailingAnchor),
            self.tabBarShadowView.topAnchor.constraint(equalTo: self.tabBarView.topAnchor),
            self.tabBarShadowView.bottomAnchor.constraint(equalTo: self.tabBarView.bottomAnchor),
            self.tabBarShadowView.leadingAnchor.constraint(equalTo: self.tabBarView.leadingAnchor),
            self.tabBarShadowView.trailingAnchor.constraint(equalTo: self.tabBarView.trailingAnchor)
        ])
    }
    
    private func setupButtons() {
        
        guard self.tabBarStackView.arrangedSubviews.count == 0 else {
            return
        }
        
        for (index, viewController) in viewControllers.enumerated() {
            
            let item = CustomTabBarItem()
            item.setTag(index)
            item.setItem(viewController.tabBarItem)
            item.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            item.titleColor = self.titleColor
            item.selectedTitleColor = self.selectedTitleColor
            
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
            //            view.insertSubview(selectedVC.view, belowSubview: tabBarShadowView)
            selectedVC.view.frame = view.bounds
            selectedVC.didMove(toParent: self)
            
            self.delegate?.tabBarController(self, didSelect: selectedVC)
            
            self.items.forEach { $0.isSelected = ($0.tag == selectedIndex) }
        }
    }
    
    private func setMargin() {
        
        self.tabBarHeight.constant = self.height
        self.tabBarBottom.constant = -self.bottom
        self.tabBarLeading.constant = self.leading
        self.tabBarTrailing.constant = -self.trailing
        
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
    
    public func setItemColors(normal titleColor: UIColor? = nil,
                              selected selectedTitleColor: UIColor? = nil) {
        
        if let titleColor = titleColor {
            self.titleColor = titleColor
            self.selectedTitleColor = selectedTitleColor ?? titleColor
        }
    }
    
    public func setBackground(_ color: UIColor) {
        self.tabBarView.backgroundColor = color
    }
    
    public func setLayoutMargin(height: CGFloat = 50, bottom: CGFloat = 0,
                                leading: CGFloat = 20, trailing: CGFloat = 20,
                                cornerRadius: CGFloat? = nil) {
        
        self.height = height
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
        
        if let cornerRadius = cornerRadius {
            self.cornerRadius = cornerRadius
        }
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
    
    public func setTabBarItem(_ image: String, selectedImage: String, vc: UIViewController, title: String? = nil) {
        let item = UITabBarItem()
        item.image = UIImage(systemName: image)
        item.selectedImage = UIImage(systemName: selectedImage)
        item.title = title
        vc.tabBarItem = item
    }
}
