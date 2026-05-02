//
//  MyPageCell.swift
//  Presentation
//
//  Created by sanghyeon on 4/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import UIKit
import Combine

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
    private let styleIconView: UIImageView = UIImageView()
    
    private let switchView: UISwitch = {
        let switchView = UISwitch()
        switchView.onTintColor = Theme.primary
        switchView.tintColor = Theme.background
        return switchView
    }()
    
    private let topSeperator: UIView = UIView(backgroundColor: Theme.strokeSoft)
    private let bottomSeperator: UIView = UIView(backgroundColor: Theme.strokeSoft)
    
    private var isPrimary: Bool = true
    private var hasStyle: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupView()
        self.selectionStyle = .none
//        self.sutupBinding()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if hasStyle {
            print("setHighlighted")
            if highlighted {
                self.boxView.backgroundColor = (isPrimary ? Theme.surfaceWarm:Theme.surfaceCool)
                self.boxCoverView.backgroundColor = (isPrimary ? Theme.surfaceWarm:Theme.surfaceCool)
            } else {
                self.boxView.backgroundColor = Theme.surface
                self.boxCoverView.backgroundColor = Theme.surface
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if hasStyle {
            print("setSelected")
            if selected {
                self.boxView.backgroundColor = (isPrimary ? Theme.surfaceWarm:Theme.surfaceCool)
                self.boxCoverView.backgroundColor = (isPrimary ? Theme.surfaceWarm:Theme.surfaceCool)
                UIView.animate(withDuration: 0.5, delay: 0.1) {
                    self.boxView.backgroundColor = Theme.surface
                    self.boxCoverView.backgroundColor = Theme.surface
                }
            } else {
                self.boxView.backgroundColor = Theme.surface
                self.boxCoverView.backgroundColor = Theme.surface
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("MyCell does not support NSCoding")
    }
    
    private func setupView() {
        
        backgroundColor = .clear
        iconView.contentMode = .scaleAspectFit
        
        coverView.layer.cornerRadius = 17
        coverView.layer.masksToBounds = true
        
        topSeperator.isHidden = true
        bottomSeperator.isHidden = true
        
        switchView.isHidden = true
        valueLabel.isHidden = true
        styleIconView.isHidden = true
        styleIconView.contentMode = .scaleAspectFit
        styleIconView.tintColor = Theme.textSecondary
        
        contentView.addSubview(boxView)
        contentView.addSubview(boxCoverView)
        boxCoverView.addSubview(coverView)
        coverView.addSubview(iconView)
        boxCoverView.addSubview(titleLabel)
        boxCoverView.addSubview(valueLabel)
        boxCoverView.addSubview(styleIconView)
        boxCoverView.addSubview(switchView)
        boxCoverView.addSubview(topSeperator)
        boxCoverView.addSubview(bottomSeperator)
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
        
        styleIconView.snp.makeConstraints { make in
            make.centerY.equalTo(boxView)
            make.height.width.equalTo(16)
            make.trailing.equalTo(boxView).offset(-14)
        }
        
        switchView.snp.makeConstraints { make in
            make.centerY.equalTo(boxView)
//            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
            make.trailing.equalTo(boxView).offset(-14)
        }
        
        topSeperator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(boxView).offset(-14)
            make.top.equalTo(boxView)
        }
        
        bottomSeperator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(boxView).offset(-14)
            make.bottom.equalTo(boxView)
        }
    }
    
    func configure(with data: MyCellData, cellPosition: CellPosition) {
        
        isPrimary = data.isPrimary
        boxView.applyStyle(cellPosition)
        switch cellPosition {
        case .single:
            topSeperator.isHidden = true
            bottomSeperator.isHidden = true
            boxCoverView.snp.updateConstraints { make in
                make.leading.trailing.equalTo(boxView).inset(1)
                make.top.equalTo(boxView).offset(18)
                make.bottom.equalTo(boxView).offset(-18)
            }
        case .top:
            topSeperator.isHidden = true
            bottomSeperator.isHidden = false
            boxCoverView.snp.updateConstraints { make in
                make.leading.trailing.equalTo(boxView).inset(1)
                make.top.equalTo(boxView).offset(18)
                make.bottom.equalTo(boxView)
            }
        case .bottom:
            topSeperator.isHidden = false
            bottomSeperator.isHidden = true
            boxCoverView.snp.updateConstraints { make in
                make.leading.trailing.equalTo(boxView).inset(1)
                make.top.equalTo(boxView)
                make.bottom.equalTo(boxView).offset(-18)
            }
        case .middle:
            topSeperator.isHidden = true
            bottomSeperator.isHidden = true
            boxCoverView.snp.updateConstraints { make in
                make.leading.trailing.equalTo(boxView).inset(1)
                make.top.bottom.equalTo(boxView)
            }
        }
        
        let icon = (UIImage(named: data.type.icon, in: .module, with: nil) ?? UIImage(systemName: data.type.icon))?.withRenderingMode(.alwaysTemplate)
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
        
        let styleIcon = UIImage(systemName: data.type.style.icon)?.withRenderingMode(.alwaysTemplate)
        switch data.type.style {
        case .info:
            hasStyle = false
            switchView.isHidden = true
            valueLabel.isHidden = false
            styleIconView.isHidden = true
            valueLabel.snp.updateConstraints { make in
                make.trailing.equalTo(boxView).offset(-14)
            }
            titleLabel.textColor = Theme.textPrimary
        case .open:
            hasStyle = true
            switchView.isHidden = true
            valueLabel.isHidden = false
            styleIconView.isHidden = false
            styleIconView.image = styleIcon
            valueLabel.snp.updateConstraints { make in
                make.trailing.equalTo(boxView).offset(-36)
            }
            titleLabel.textColor = Theme.textPrimary
        case .toggle:
            hasStyle = false
            switchView.isHidden = false
            valueLabel.isHidden = true
            styleIconView.isHidden = true
            titleLabel.textColor = Theme.textPrimary
        case .link:
            hasStyle = true
            switchView.isHidden = true
            valueLabel.isHidden = false
            styleIconView.isHidden = false
            styleIconView.image = styleIcon
            valueLabel.snp.updateConstraints { make in
                make.trailing.equalTo(boxView).offset(-36)
            }
            titleLabel.textColor = Theme.textPrimary
        case .button:
            hasStyle = true
            switchView.isHidden = true
            valueLabel.isHidden = true
            styleIconView.isHidden = true
            
            if data.isPrimary {
                titleLabel.textColor = Theme.primary
            } else {
                titleLabel.textColor = Theme.secondary
            }
        }
    }
}
