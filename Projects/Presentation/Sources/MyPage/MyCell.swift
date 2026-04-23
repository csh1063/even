//
//  MyCell.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

final class MyCell: UITableViewCell {
    
    static var cellName: String {
        return "\(Self.self)"
    }
    
    private let label: UILabel = UILabel()
    private let arrowImageView: UIImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("MyCell does not support NSCoding")
    }
    
    func setupView() {
        
        contentView.backgroundColor = Theme.background
        
        label.textColor = Theme.text
        label.font = UIFont.systemFont(ofSize: 16)
        
        let image = UIImage(systemName: "chevron.forward")
        arrowImageView.image = image?.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = Theme.text
        
        addSubview(label)
        addSubview(arrowImageView)
        
        label.snp.makeConstraints { make in
            make.top.bottom.equalTo(self)
            make.leading.equalTo(self).inset(20)
            make.height.equalTo(40)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(label.snp.trailing)
            make.trailing.equalTo(self).inset(20)
            make.width.height.equalTo(12)
        }
    }
    
    func configure(with type: MyPageCellType) {
        label.text = type.text
    }
}
