//
//  TabbarViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

final class TabbarViewController: CustomTabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setItemColors(
            normal: .Theme.gray,
            selected: .Theme.primary)
        
        self.setLayoutMargin(height: 56,
                             margin: .init(leading: 80, trailing: 80, bottom: 4),
                             padding: .init(leading: 12, trailing: 12),
                             cornerRadius: 28)
//        self.setLayoutMargin(height: 56, bottom: 4,
//                             leading: 80, trailing: 80, cornerRadius: 28)
        
        self.setShadow(color: .black, alpha: 0.1, x: 0, y: 4, blur: 16)
        
        self.selectedIndex = 1
    }
}
