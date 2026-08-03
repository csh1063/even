//
//  AnalyticsTracker.swift
//  Presentation
//
//  Created by sanghyeon on 7/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

// Presentation은 Firebase를 직접 의존하지 않는다(AlertManager/LoadingManager와 같은 싱글톤
// 패턴) — 실제 로깅 구현(FirebaseAnalytics)은 App이 시작 시점에 logHandler로 주입한다.
public final class AnalyticsTracker {

    public static let shared = AnalyticsTracker()
    private init() {}

    public var logHandler: ((String) -> Void)?

    public func logScreenView(_ pageTitle: String) {
        logHandler?(pageTitle)
    }
}
