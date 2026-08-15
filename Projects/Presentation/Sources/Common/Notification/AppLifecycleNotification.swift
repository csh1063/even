//
//  AppLifecycleNotification.swift
//  Presentation
//
//  Created by sanghyeon on 8/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public extension Notification.Name {
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
    static let appWillEnterForeground = Notification.Name("appWillEnterForeground")
}
