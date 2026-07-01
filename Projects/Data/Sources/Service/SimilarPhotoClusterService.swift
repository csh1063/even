//
//  SimilarPhotoClusterService.swift
//  Data
//
//  Created by sanghyeon on 6/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Vision
import Domain

public final class SimilarPhotoClusterService {

    public let threshold: Float
    public let timeWindowMinutes: Double

    public init(threshold: Float = 0.3, timeWindowMinutes: Double = 5) {
        self.threshold = threshold
        self.timeWindowMinutes = timeWindowMinutes
    }

    /// featurePrintData와 createdAt을 가진 도메인 모델
    public struct PhotoPrint {
        public let localIdentifier: String
        public let featurePrintData: Data
        public let createdAt: Date

        public init(localIdentifier: String, featurePrintData: Data, createdAt: Date) {
            self.localIdentifier = localIdentifier
            self.featurePrintData = featurePrintData
            self.createdAt = createdAt
        }
    }

    /// 클러스터링 결과: [clusterId: [localIdentifier]]
    public func cluster(photos: [PhotoPrint]) -> [String: [String]] {
        guard !photos.isEmpty else { return [:] }

        let sorted = photos.sorted { $0.createdAt < $1.createdAt }
        var parent: [String: String] = Dictionary(uniqueKeysWithValues: sorted.map { ($0.localIdentifier, $0.localIdentifier) })

        func find(_ x: String) -> String {
            var x = x
            while parent[x] != x {
                parent[x] = parent[parent[x]!]!
                x = parent[x]!
            }
            return x
        }

        func union(_ x: String, _ y: String) {
            let rx = find(x), ry = find(y)
            if rx != ry { parent[rx] = ry }
        }

        let windowSeconds = timeWindowMinutes * 60

        for i in 0..<sorted.count {
            for j in (i+1)..<sorted.count {
                let timeDiff = sorted[j].createdAt.timeIntervalSince(sorted[i].createdAt)
                if timeDiff > windowSeconds { break }

                guard let distance = try? computeDistance(
                    from: sorted[i].featurePrintData,
                    to: sorted[j].featurePrintData
                ) else { continue }

                if distance < threshold {
                    union(sorted[i].localIdentifier, sorted[j].localIdentifier)
                }
            }
        }

        // 루트별로 그룹핑
        var groups: [String: [String]] = [:]
        for photo in sorted {
            let root = find(photo.localIdentifier)
            groups[root, default: []].append(photo.localIdentifier)
        }

        // 2장 이상인 그룹만 반환
        return groups.filter { $0.value.count >= 2 }
    }

    // MARK: - Private

    private func computeDistance(from lhs: Data, to rhs: Data) throws -> Float {
        guard
            let lhsObs = try NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: lhs),
            let rhsObs = try NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: rhs)
        else {
            throw FeaturePrintError.deserializationFailed
        }

        var distance: Float = 0
        try lhsObs.computeDistance(&distance, to: rhsObs)
        return distance
    }
}
