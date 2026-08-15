//
//  LiveActivityManager.swift
//  Presentation
//
//  Created by sanghyeon on 8/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import ActivityKit
import Domain
import PhotoAnalysisActivity

/// 사진 분석 진행률을 다이나믹 아일랜드/잠금화면 Live Activity로 보여준다.
/// 앱이 실제로 실행 코드를 돌리고 있는 동안(포그라운드, beginBackgroundTask 유예시간,
/// BGProcessingTask 실행 구간)에만 update가 가능하고, 그 사이 구간에는 마지막 값에서 멈춰있는다.
public final class LiveActivityManager {

    public static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<PhotoAnalysisActivityAttributes>?

    public func start() {
        guard activity == nil else { return }

        // BGProcessingTask가 앱을 백그라운드로 재실행시키는 경우, 이 싱글턴은 새 프로세스에서
        // 새로 만들어지지만 Live Activity 자체는 시스템이 앱 프로세스와 별개로 계속 들고 있다 —
        // 새로 만들지 않고 기존 걸 다시 붙잡는다.
        if let existing = Activity<PhotoAnalysisActivityAttributes>.activities.first {
            activity = existing
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        do {
            activity = try Activity.request(
                attributes: PhotoAnalysisActivityAttributes(),
                content: .init(state: .init(progress: 0), staleDate: nil)
            )
        } catch {
            debugLog("⚠️ Live Activity 시작 실패: \(error)")
        }
    }

    public func update(progress: Double) async {
        guard let activity else { return }
        await activity.update(.init(state: .init(progress: progress), staleDate: nil))
    }

    public func end() async {
        guard let activity else { return }
        await activity.end(
            .init(state: .init(progress: 1.0), staleDate: nil),
            dismissalPolicy: .after(Date().addingTimeInterval(3))
        )
        self.activity = nil
    }
}
