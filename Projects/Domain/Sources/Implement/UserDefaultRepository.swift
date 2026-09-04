//
//  UserDefaultRepository.swift
//  Domain
//
//  Created by sanghyeon on 5/1/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol UserDefaultRepository {
    func saveAnalyzedDate() async throws
    func fetchAnalyzedDate() async throws -> String
    func resetAnalyzedDate() async throws
    func saveLocationAnalyzedDate() async throws
    func fetchLocationAnalyzedDate() async throws -> String
    func saveDisplayMode(_ mode: String) async throws
    func fetchDisplayMode() async throws -> String
    func saveAutoNewAnalysis(isOn: Bool) async throws
    func fetchAutoNewAnalysis() async throws -> Bool?
    func saveOnboarding(isShown: Bool) async throws
    func showOnboarding() async throws -> Bool
    func saveConsent(isShown: Bool) async throws
    func showConsent() async throws -> Bool

    /// 여행 앨범 재계산(기존 앨범 삭제 → 재클러스터링 → 재저장)을 시작하기 직전에 호출 —
    /// anchorDate까지는 안전하게 확정된 상태라는 걸 기록해둔다(nil이면 첫 여행 앨범부터 다시 만드는 중).
    /// 재계산이 끝까지 성공하면 clearTravelAlbumCheckpoint()로 지운다. 앱이 그 사이에 죽으면 이 값이
    /// 남아있으므로, 다음 실행에서 "지난번이 완료 안 됐다"는 걸 알고 이 anchorDate 기준으로 다시 만든다.
    func beginTravelAlbumCheckpoint(anchorDate: Date?) async throws
    func clearTravelAlbumCheckpoint() async throws
    /// nil이면 체크포인트 없음(지난 실행이 정상 종료됨)
    func fetchTravelAlbumCheckpoint() async throws -> TravelAlbumCheckpoint?
}

public struct TravelAlbumCheckpoint {
    public let anchorDate: Date?

    public init(anchorDate: Date?) {
        self.anchorDate = anchorDate
    }
}
