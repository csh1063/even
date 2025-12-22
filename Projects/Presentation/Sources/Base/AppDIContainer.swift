//
//  AppDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 12/18/25.
//  Copyright © 2025 sanghyeon. All rights reserved.
//

import Foundation

public protocol AppDIContainer {
    func makeSplashViewModel() -> SplashViewModel
    func makeMainViewModel() -> MainViewModel
}

