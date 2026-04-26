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
        
        self.setBackgroundColor(Theme.surface.withAlphaComponent(0.72))
        
        self.setItemColors(
            normal: Theme.textSecondary,
            selected: .white)
        
        self.setLayoutMargin(height: 68,
                             margin: .init(leading: 20, trailing: 20, bottom: 10),
                             padding: .init(leading: 12, trailing: 12),
                             cornerRadius: 28)
//        self.setLayoutMargin(height: 56, bottom: 4,
//                             leading: 80, trailing: 80, cornerRadius: 28)
        
        self.setShadow(color: .black, alpha: 0.1, x: 0, y: 4, blur: 16)
        
        self.setSelectedBox(radius: 26, color: Theme.primary)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.selectedIndex = 1
    }
    
    func showTabbar() {
        self.animateFade(isShow: true)
    }
    
    func hideTabbar() {
        self.animateFade(isShow: false)
    }
}

extension TabbarViewController: CustomTabBarDelegate {
    
}
