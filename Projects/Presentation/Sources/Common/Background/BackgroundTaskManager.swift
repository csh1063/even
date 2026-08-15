//
//  BackgroundTaskManager.swift
//  Presentation
//
//  Created by sanghyeon on 8/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit

/// 앱이 백그라운드로 전환될 때 beginBackgroundTask로 짧은 유예시간을 확보해준다.
/// 유예시간은 iOS/기기 상태에 따라 변동적이며 보장되지 않는다.
public final class BackgroundTaskManager {

    public static let shared = BackgroundTaskManager()
    private init() {}

    private var taskId: UIBackgroundTaskIdentifier = .invalid

    public var isRunning: Bool { taskId != .invalid }

    public func begin(name: String = "PhotoAnalysis", expirationHandler: @escaping () -> Void) {
        guard taskId == .invalid else { return }
        taskId = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            // expirationHandler는 메인 스레드 보장이 없다 — end()가 MainActor인 TabbarViewModel 상태를
            // 건드리는 클로저를 호출하므로 반드시 MainActor로 넘긴다.
            Task { @MainActor in
                expirationHandler()
                self?.end()
            }
        }
    }

    public func end() {
        guard taskId != .invalid else { return }
        UIApplication.shared.endBackgroundTask(taskId)
        taskId = .invalid
    }
}
