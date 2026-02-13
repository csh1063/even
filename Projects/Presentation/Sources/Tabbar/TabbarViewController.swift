//
//  TabbarViewController.swift
//  Presentation
//
//  Created by sanghyeon on 12/22/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

final class TabbarViewController: CustomTabBarController {
    
//    init() {
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    public required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLayoutMargin(height: 56, bottom: 4,
                             leading: 40, trailing: 40, cornerRadius: 28)
        
        self.setShadow(color: .black, alpha: 0.1, x: 0, y: 4, blur: 6)
        
        self.selectedIndex = 1
    }
}
