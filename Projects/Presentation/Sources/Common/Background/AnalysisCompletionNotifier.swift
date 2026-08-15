//
//  AnalysisCompletionNotifier.swift
//  Presentation
//
//  Created by sanghyeon on 8/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import UIKit
import UserNotifications

/// 사진 분석이 백그라운드에서 완료됐을 때 사용자가 앱을 지켜보지 않아도 되도록 로컬 알림을 보낸다.
public enum AnalysisCompletionNotifier {

    private static let notificationIdentifier = "photoAnalysisCompleted"

    public static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// 앱이 foreground일 때는 사용자가 이미 보고 있으므로 알림을 띄우지 않는다.
    public static func notifyIfBackgrounded() {
        guard UIApplication.shared.applicationState != .active else { return }
        notify()
    }

    public static func notify() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "사진 분석 완료", bundle: .module)
        content.body = String(localized: "사진 분석이 끝났어요. 앱에서 확인해보세요.", bundle: .module)
        content.sound = .default
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
