//
//  TravelDetectionRepository.swift
//  Domain
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public protocol TravelDetectionRepository {
//    func detect(from photos: [PhotoLocationSnapshot]) async throws -> [TravelCluster]
    func detect(from photos: [PhotoLocationSnapshot], homeZones: [HomeZone]) async throws -> [TravelCluster]
    /// 주어진 사진들로부터 대표 주소/기간을 계산해 하나의 TravelCluster를 만든다 (여행 앨범 합치기에서 재사용)
    func buildCluster(from photos: [PhotoLocationSnapshot]) async throws -> TravelCluster?
}
