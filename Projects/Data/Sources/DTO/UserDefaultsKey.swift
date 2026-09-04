//
//  UserDefaultsKey.swift
//  Data
//
//  Created by sanghyeon on 5/1/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public enum UserDefaultsKey {
    public static let lastAnalyzedDate = "lastAnalyzedDate"
    public static let lastLocationAnalyzedDate = "lastLocationAnalyzedDate"
    public static let displayMode = "displayMode"
    public static let autoNewAnalysis = "autoNewAnalysis"
    public static let showOnboarding = "showOnboarding"
    public static let showConsent = "showConsent"
    /// 여행 앨범 재계산(삭제 후 재생성) 도중 비정상 종료됐는지 표시하는 체크포인트
    public static let travelAlbumCheckpointPending = "travelAlbumCheckpointPending"
    /// 체크포인트가 있을 때, 그 이전까지는 안전하게 확정돼 있던 마지막 여행 앨범의 끝 날짜
    public static let travelAlbumCheckpointAnchorDate = "travelAlbumCheckpointAnchorDate"
}
