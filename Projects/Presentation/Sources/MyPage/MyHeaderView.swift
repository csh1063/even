//
//  MyHeaderView.swift
//  Presentation
//
//  Created by sanghyeon on 4/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

final class MyHeaderView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = Theme.textPrimary
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("MyHeaderView does not support NSCoding.")
    }
    
    private func setupView() {
        addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalTo(self).inset(14)
            make.leading.trailing.equalTo(self).inset(20)
        }
    }
    
    func configuration(with data: MyCellHeader) {
        self.titleLabel.text = data.name
    }
}
