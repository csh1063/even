//
//  MyPageCell.swift
//  Presentation
//
//  Created by sanghyeon on 4/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit

enum CellPosition {
    case top, middle, bottom, single
}

final class MyPageCell: UITableViewCell {
    
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
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = Theme.textSecondary
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
        self.selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("MyCell does not support NSCoding")
    }
    
    func setupView() {
        
        backgroundColor = .clear
        iconView.contentMode = .scaleAspectFit
        
        coverView.layer.cornerRadius = 17
        coverView.layer.masksToBounds = true
        
        contentView.addSubview(boxView)
        contentView.addSubview(boxCoverView)
        boxCoverView.addSubview(coverView)
        coverView.addSubview(iconView)
        boxCoverView.addSubview(titleLabel)
        boxCoverView.addSubview(valueLabel)
        boxCoverView.addSubview(switchView)
        
        boxView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView).inset(20)
            make.top.bottom.equalTo(contentView)
        }
        
        boxCoverView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(boxView).inset(1)
            make.top.equalTo(boxView)
            make.bottom.equalTo(boxView)
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
        
        valueLabel.snp.makeConstraints { make in
            make.centerY.equalTo(boxView)
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.trailing.equalTo(boxView).offset(-14)
        }
        
        switchView.snp.makeConstraints { make in
            make.centerY.equalTo(boxView)
//            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.trailing.equalTo(boxView).offset(-14)
        }
    }
    
    func configure(with data: MyCellData, cellPosition: CellPosition) {
        
        boxView.applyStyle(cellPosition)
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
        switchView.isHidden = true
        valueLabel.isHidden = true
        
        let icon = UIImage(systemName: data.type.icon)?.withRenderingMode(.alwaysTemplate)
        iconView.image = icon
        titleLabel.text = data.type.text
        valueLabel.text = data.value
        switchView.isOn = data.isOn
        
        if data.isPrimary {
            coverView.backgroundColor = Theme.surfaceWarm
            iconView.tintColor = Theme.primary
            switchView.isHidden = true
            valueLabel.isHidden = false
        } else {
            coverView.backgroundColor = Theme.surfaceCool
            iconView.tintColor = Theme.secondary
            switchView.isHidden = false
            valueLabel.isHidden = true
        }
    }
}
