//
//  BackgroundProcessingScheduler.swift
//  Presentation
//
//  Created by sanghyeon on 8/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import BackgroundTasks
import Domain

/// beginBackgroundTask의 짧은 유예시간 안에 사진 분석이 끝나지 못했을 때, 시스템이 기기 유휴 상태를
/// 봐가며 알아서 이어서 실행하도록 BGProcessingTask를 예약/처리한다. 실행 시점은 시스템이 결정하므로
/// 즉시 실행을 보장하지 않는다.
public final class BackgroundProcessingScheduler {

    public static let shared = BackgroundProcessingScheduler()
    private init() {}

    public static let taskIdentifier = "com.moa.photoAnalysis"

    private var analysisUseCase: PhotoAnalysisUseCase?

    public func configure(analysisUseCase: PhotoAnalysisUseCase) {
        self.analysisUseCase = analysisUseCase
    }

    /// AppDelegate의 didFinishLaunchingWithOptions에서 앱이 완전히 launch를 끝내기 전에 호출돼야 한다.
    public func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { [weak self] task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self?.handle(processingTask)
        }
    }

    public func schedule() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            debugLog("⚠️ BGProcessingTask 예약 실패: \(error)")
        }
    }

    private func handle(_ task: BGProcessingTask) {
        guard let analysisUseCase else {
            task.setTaskCompleted(success: false)
            return
        }

        let work = Task {
            do {
                // 유예시간 만료 전에 이미 포그라운드에서 끝났을 수 있으므로, 정말 중단된 상태일 때만 이어간다.
                guard try await analysisUseCase.isAnalysisInterrupted() else {
                    task.setTaskCompleted(success: true)
                    return
                }

                for try await _ in analysisUseCase.analysis() {
                    try Task.checkCancellation()
                }

                try? await analysisUseCase.markAnalysisFinished()
                task.setTaskCompleted(success: true)
                AnalysisCompletionNotifier.notify()
            } catch {
                // 이번에도 시간 안에 못 끝났으면(취소/에러 모두) 다음 기회를 다시 예약한다.
                schedule()
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            work.cancel()
        }
    }
}
