//
//  CustomTabBarItem.swift
//  RxTest
//
//  Created by sanghyeon on 6/27/24.
//

import Foundation
import UIKit

class CustomTabBarItem: UIView {
    
    var coverView: UIStackView = UIStackView()
    
    let imageCoverView = UIView()
    var imageView: UIImageView = UIImageView()
    let button: UIButton = UIButton()
    var label: UILabel?
    
    var titleColor: UIColor = .gray {
        didSet {
            self.image = self.image?.withTintColor(
                self.titleColor,
                renderingMode: .alwaysOriginal)
            if !self.isSelected {
                self.imageView.image = self.image
                self.label?.textColor = titleColor
            }
        }
    }
    var selectedTitleColor: UIColor = .black {
        didSet {
            self.selectedImage = self.selectedImage?.withTintColor(
                self.selectedTitleColor,
                renderingMode: .alwaysOriginal)
            if self.isSelected {
                self.imageView.image = self.selectedImage
                self.label?.textColor = self.selectedTitleColor
            }
        }
    }
    
    var image: UIImage?
    var selectedImage: UIImage?
    
    var isSelected: Bool {
        get {
            return button.isSelected
        }
        set {
            button.isSelected = newValue
            if newValue {
                self.imageView.image = selectedImage
                self.label?.textColor = selectedTitleColor
            } else {
                self.imageView.image = image
                self.label?.textColor = titleColor
            }
            self.layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.settings()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.settings()
    }
    
    private func settings() {

        self.addSubview(coverView)
        
        self.coverView.axis = .vertical
        self.coverView.spacing = 4
        self.coverView.alignment = .center
        self.coverView.distribution = .fill
        
        self.coverView.translatesAutoresizingMaskIntoConstraints = false
        self.coverView.topAnchor.constraint(equalTo: self.topAnchor, constant: 4).isActive = true
        self.bottomAnchor.constraint(equalTo: self.coverView.bottomAnchor, constant: 4).isActive = true
        self.coverView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.coverView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    
    func setItem(_ item: UITabBarItem) {
        
        self.image = item.image?.withTintColor(self.titleColor, renderingMode: .alwaysOriginal) ?? item.image
        self.selectedImage = item.selectedImage?.withTintColor(self.selectedTitleColor, renderingMode: .alwaysOriginal) ?? item.selectedImage
        
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageCoverView.translatesAutoresizingMaskIntoConstraints = false
        
        self.imageCoverView.addSubview(self.imageView)
        self.coverView.addArrangedSubview(self.imageCoverView)
        
        self.imageCoverView.widthAnchor.constraint(equalTo: self.coverView.widthAnchor).isActive = true
        self.imageView.topAnchor.constraint(greaterThanOrEqualTo: self.imageCoverView.topAnchor).isActive = true
        self.imageView.bottomAnchor.constraint(lessThanOrEqualTo: self.imageCoverView.bottomAnchor).isActive = true
        self.imageView.centerXAnchor.constraint(equalTo: self.imageCoverView.centerXAnchor).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.imageCoverView.centerYAnchor).isActive = true
        
        self.addSubview(button)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.button.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.button.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        if let text = item.title {
            
            self.label = {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 10)
                label.textAlignment = .center
                return label
            }()
            
            if let label {
                self.coverView.addArrangedSubview(label)
            }
            self.setTitle(text)
        } else {
            for subview in self.coverView.arrangedSubviews {
                self.coverView.removeArrangedSubview(subview)
            }
        }
    }
    
    private func setTitle(_ title: String) {
        
        self.label?.text = title
        self.label?.textColor = self.titleColor
    }
    
    func setTag(_ tag: Int) {
        self.button.tag = tag
        self.tag = tag
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        self.button.addTarget(target, action: action, for: controlEvents)
    }
}



//class CustomTabBarItem: UIView {
//    
//    var coverView: UIView = UIView()
//    let button: UIButton = UIButton()
//    var label: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 8)
//        label.textAlignment = .center
//        return label
//    }()
//    
//    var titleColor: UIColor = .gray
//    var selectedTitleColor: UIColor = .black
//    
//    var isSelected: Bool {
//        get {
//            return button.isSelected
//        }
//        set {
//            button.isSelected = newValue
//            if newValue {
//                label.textColor = selectedTitleColor
//            } else {
//                label.textColor = titleColor
//            }
//        }
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.settings()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        self.settings()
//    }
//    
//    private func settings() {
//
//        self.addSubview(coverView)
//        self.coverView.translatesAutoresizingMaskIntoConstraints = false
//        self.coverView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
//        self.coverView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
//        self.coverView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
//        self.coverView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
//    }
//    
//    func setItem(_ item: UITabBarItem) {
//        
//        self.button.setImage(
//            item.image?.withTintColor(self.titleColor, renderingMode: .alwaysOriginal) ?? item.image, for: .normal)
//        
//        self.button.setImage(item.selectedImage?.withTintColor(self.selectedTitleColor, renderingMode: .alwaysOriginal) ?? item.selectedImage, for: .selected)
//        
//        self.coverView.addSubview(button)
//        
//        self.button.translatesAutoresizingMaskIntoConstraints = false
//        self.button.topAnchor.constraint(equalTo: self.coverView.topAnchor, constant: 4).isActive = true
//        self.button.leadingAnchor.constraint(equalTo: self.coverView.leadingAnchor).isActive = true
//        self.button.trailingAnchor.constraint(equalTo: self.coverView.trailingAnchor).isActive = true
//        
//        if let text = item.title {
//            
//            self.coverView.addSubview(label)
//            self.label.translatesAutoresizingMaskIntoConstraints = false
//            self.label.topAnchor.constraint(equalTo: self.button.bottomAnchor, constant: 4).isActive = true
//            self.coverView.leadingAnchor.constraint(equalTo: self.label.leadingAnchor).isActive = true
//            self.coverView.trailingAnchor.constraint(equalTo: self.label.trailingAnchor).isActive = true
//            self.coverView.bottomAnchor.constraint(equalTo: self.label.bottomAnchor, constant: 8).isActive = true
//            self.label.heightAnchor.constraint(equalToConstant: 8).isActive = true
//            
//            self.setTitle(text)
//        } else {
//            self.coverView.bottomAnchor.constraint(equalTo: self.button.bottomAnchor, constant: 4).isActive = true
//        }
//    }
//    
//    private func setTitle(_ title: String) {
//        
//        self.label.text = title
//        self.label.textColor = self.titleColor
//    }
//    
//    func setTag(_ tag: Int) {
//        self.button.tag = tag
//        self.tag = tag
//    }
//    
//    func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
//        self.button.addTarget(target, action: action, for: controlEvents)
//    }
//}
