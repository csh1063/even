//
//  NaviButtonSetting.swift
//  Presentation
//
//  Created by sanghyeon on 4/8/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

protocol NaviButtonSetting {
    var isLeft: Bool { get }
    var type: NaviBarButtonType { get }
//    var color: UIColor { get }
}

struct LeftButton: NaviButtonSetting {
    
    let isLeft = true
    var type: NaviBarButtonType
//    var color: UIColor
    
    init(type: NaviBarButtonType) {//}, color: UIColor = Theme.textPrimary) {
        self.type = type
//        self.color = color
    }
}

struct RightButton: NaviButtonSetting {
    
    let isLeft = false
    var type: NaviBarButtonType
//    var color: UIColor
    
    init(type: NaviBarButtonType) {//}, color: UIColor) {
        self.type = type
//        self.color = color
    }
}
