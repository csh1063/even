//
//  ProgressState.swift
//  Domain
//
//  Created by sanghyeon on 3/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public enum ProgressState {
    case progress(Double)
    case completed
    case unavailable(reason: String)  // 모델 로드 실패 등
}
