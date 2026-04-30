//
//  MyPageSwitchCell.swift
//  Presentation
//
//  Created by sanghyeon on 4/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

final class MyPageSwitchCell: UITableViewCell {
    
    static var cellName: String {
        return "\(Self.self)"
    }
    
    private let boxView: BoxView = {
        let view = BoxView()
        view.backgroundColor = Theme.surface
        return view
    }()
    private let boxCoverView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.surface
        return view
    }()
    private let coverView: UIView = UIView()
    private let iconView: UIImageView = UIImageView()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = Theme.textPrimary
        return label
    }()
    
    private let switchView: UISwitch = {
        let switchView = UISwitch()
        switchView.onTintColor = Theme.primary
        switchView.tintColor = Theme.background
        return switchView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("MyCell does not support NSCoding")
    }
    
    func setupView() {
        
        backgroundColor = .clear
        
        coverView.layer.cornerRadius = 17
        coverView.layer.masksToBounds = true
        
        addSubview(boxView)
        addSubview(boxCoverView)
        boxCoverView.addSubview(coverView)
        coverView.addSubview(iconView)
        boxCoverView.addSubview(titleLabel)
        boxCoverView.addSubview(switchView)
        
        boxView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(20)
            make.top.bottom.equalTo(self)
        }
        
        boxCoverView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(boxView).inset(1)
            make.top.bottom.equalTo(boxView)
        }
        
        coverView.snp.makeConstraints { make in
            make.width.height.equalTo(34)
            make.top.bottom.equalTo(boxView).inset(12)
            make.leading.equalTo(boxView).offset(14)
        }
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.center.equalTo(coverView)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(boxView)
            make.leading.equalTo(coverView.snp.trailing).offset(12)
        }
        
        switchView.snp.makeConstraints { make in
            make.centerY.equalTo(boxView)
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.trailing.equalTo(boxView).offset(-14)
        }
    }
    
    func configure(with data: MyCellData, cellPosition: CellPosition) {
        
        switch cellPosition {
        case .single:
            boxCoverView.snp.updateConstraints { make in
                make.leading.trailing.equalTo(boxView).inset(1)
                make.top.equalTo(boxView).offset(18)
                make.bottom.equalTo(boxView).offset(-18)
            }
        case .top:
            boxCoverView.snp.updateConstraints { make in
                make.leading.trailing.equalTo(boxView).inset(1)
                make.top.equalTo(boxView).offset(18)
                make.bottom.equalTo(boxView)
            }
        case .bottom:
            boxCoverView.snp.updateConstraints { make in
                make.leading.trailing.equalTo(boxView).inset(1)
                make.top.equalTo(boxView)
                make.bottom.equalTo(boxView).offset(-18)
            }
        case .middle:
            boxCoverView.snp.updateConstraints { make in
                make.leading.trailing.equalTo(boxView).inset(1)
                make.top.bottom.equalTo(boxView)
            }
        }
        
        boxView.applyStyle(cellPosition)
        
        let icon = UIImage(systemName: data.type.icon)?.withRenderingMode(.alwaysTemplate)
        iconView.image = icon
        titleLabel.text = data.type.text
        
        coverView.backgroundColor = Theme.surfaceCool
        iconView.tintColor = Theme.secondary
        switchView.isOn = data.isOn
    }
}
