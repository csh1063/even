//
//  PhotoAnalysisActivityAttributes.swift
//  PhotoAnalysisActivity
//
//  Created by sanghyeon on 8/15/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import ActivityKit

/// 앱(App 타겟)과 다이나믹 아일랜드/잠금화면 Live Activity 위젯 익스텐션이 함께 참조하는 타입.
/// 무거운 의존성(SwiftData, Vision, CoreML, Firebase 등)이 없는 이 모듈에만 둬서
/// 위젯 익스텐션 프로세스의 메모리 예산에 영향을 주지 않게 한다.
public struct PhotoAnalysisActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable, Sendable {
        public var progress: Double

        public init(progress: Double) {
            self.progress = progress
        }
    }

    public init() {}
}
