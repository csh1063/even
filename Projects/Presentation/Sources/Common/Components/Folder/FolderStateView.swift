//
//  FolderStateView.swift
//  Presentation
//
//  Created by sanghyeon on 4/23/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

final class FolderStateView: UIView {

    private let label = UILabel()
    
    private var text: String = "" {
        didSet { label.text = text }
    }
    
    private var color: UIColor = .systemBlue {
        didSet {
            label.textColor = color
            backgroundColor = color.withAlphaComponent(0.16)
        }
    }
    
    var isAuto: Bool = true {
        didSet {
            if isAuto {
                
                self.isHidden = false
                text = "AUTO"
                color = Theme.secondary
            } else {
                self.isHidden = true
                color = .clear
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) { fatalError("FolderStateView does not support NSCoding.") }
    
    private func setup() {
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5)
            make.leading.trailing.equalToSuperview().inset(8)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
        self.addBorder(color: color, borderWidth: 1)
    }
}
