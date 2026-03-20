//
//  TitleBarViewDelegate.swift
//  Presentation
//
//  Created by sanghyeon on 3/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import UIKit

// MARK: - TitleBarView Delegate

protocol TitleBarViewDelegate: AnyObject {
    func outerLeftButtonTapped(viewModel: TitleBarViewModel, sender: UIButton)
    func outerRightButtonTapped(viewModel: TitleBarViewModel, sender: UIButton)
}