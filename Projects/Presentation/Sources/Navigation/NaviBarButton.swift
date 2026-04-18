//
//  NaviBarButton.swift
//  Presentation
//
//  Created by sanghyeon on 3/29/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import Combine

final class NaviBarButton: UIView {
    
    public var buttonTintColor: UIColor {
        get {
            self.button.tintColor
        }
        set {
            self.button.tintColor = newValue
        }
    }
    
    private let button: UIButton = UIButton()
    private let dot: UIImageView = {
        let image = UIImage(systemName: "circle.fill")
        image?.withTintColor(.red, renderingMode: .alwaysTemplate)
        let imageView =  UIImageView(image: image)
        
        return imageView
    }()
    
    private let type: NaviBarButtonType
    
    var publisher: AnyPublisher<NaviBarButtonType, Never> {
        button.tapPublisher
            .map { [weak self] _ in self?.type ?? .none }
            .eraseToAnyPublisher()
    }

    init(type: NaviBarButtonType) {
        
        self.type = type
        
        super.init(frame: .zero)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("NaviBarButton dose not support")
    }
    
    private func setupView() {
        
        self.backgroundColor = .clear // .Theme.background
        dot.isHidden = true
        
        addSubview(button)
        addSubview(dot)
        
        button.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        dot.snp.makeConstraints { make in
            make.height.width.equalTo(4)
            make.top.equalTo(self).offset(12)
            make.trailing.equalTo(self).offset(-12)
        }
        
        switch type {
        case .none: break
        case .text(let text):
            self.button.setTitle(text, for: .normal)
        default:
//            let config = UIImage.SymbolConfiguration(hierarchicalColor: .Theme.primary)
//            let image = UIImage(systemName: type.imageName, withConfiguration: config)

            let image = UIImage(systemName: type.imageName)?.withRenderingMode(.alwaysTemplate)
            self.button.setImage(image, for: .normal)
//            self.button.tintColor = .Theme.primary
        }
    }
}
