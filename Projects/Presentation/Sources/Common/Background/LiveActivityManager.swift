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

    // 화면(진행률 바 2개)은 그대로 두고, Live Activity에서만 사진 분석+앨범 생성을 하나의 0~100%로 합쳐 보여준다.
    // 사진 분석(Vision/CoreML/지오코딩)이 앨범 생성(로컬 DB 작업)보다 훨씬 오래 걸리는 걸 감안한 가중치.
    private static let photoWeight: Double = 0.7
    private static let albumWeight: Double = 0.3

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

    /// 사진 분석 진행률(photoRatio)과 앨범 생성 진행률(albumRatio, 아직 시작 전이면 0)을 가중합해서
    /// 하나의 0~100%로 갱신한다.
    public func updateCombined(photoRatio: Double, albumRatio: Double) async {
        await update(progress: photoRatio * Self.photoWeight + albumRatio * Self.albumWeight)
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
