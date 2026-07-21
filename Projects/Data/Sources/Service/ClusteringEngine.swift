//
//  ClusteringEngine.swift
//  Data
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//  FaceClusterService에 있던 Chinese Whispers 기반 클러스터링 알고리즘을 사람 얼굴 전용에서
//  분리해, 개체 종류(ClusterableEmbedding를 만족하는 어떤 임베딩이든)와 임계값 설정에 무관하게
//  동작하는 공용 엔진으로 뽑아낸 것. 알고리즘 자체는 원본과 완전히 동일하고(로직/순서/동점 처리
//  전부 그대로), FaceEmbedding을 제네릭 Item으로, 클래스 상수였던 임계값들을 ClusteringConfig로
//  바꾼 것뿐이다. 사람 얼굴 클러스터링 결과가 리팩터 전후로 달라지면 안 된다.
//

import Domain
import Foundation
import Accelerate

// MARK: - ClusteringConfig

public struct ClusteringConfig {
    /// 이웃 판단 기준 — 이 값 이상이면 엣지 연결
    public var similarityThreshold: Float
    /// 최소 클러스터 크기 — 이 크기 이상인 조각들만 병합 후보로 인정
    public var minimumClusterSize: Int
    /// 병합 후 최종 크기 기준 — minimumClusterSize를 통과한 조각들을 병합한 결과가 이 값 미만이면
    /// (서로 병합 상대를 못 찾아 혼자 남은 조각 포함) 앨범으로 만들지 않고 버림
    public var minimumMergedClusterSize: Int
    /// 개별 클러스터 품질 기준 — 이 미만이면 짜투리로 버림
    public var minimumClusterQuality: Float
    /// Chinese Whispers 반복 횟수
    public var maxIterations: Int
    /// 클러스터 병합 기준 — centroid 간 유사도
    public var mergeThreshold: Float
    /// 병합 후 내부 유사도 검증 기준 (평균 기준)
    public var minimumInternalSimilarity: Float
    /// 평균이 기준을 넘어도, 다른 멤버 중 단 한 명과의 유사도라도 이 값 미만이면 아웃라이어로 판단
    public var minimumPairwiseSimilarity: Float

    public init(
        similarityThreshold: Float,
        minimumClusterSize: Int,
        minimumMergedClusterSize: Int,
        minimumClusterQuality: Float,
        maxIterations: Int,
        mergeThreshold: Float,
        minimumInternalSimilarity: Float,
        minimumPairwiseSimilarity: Float
    ) {
        self.similarityThreshold = similarityThreshold
        self.minimumClusterSize = minimumClusterSize
        self.minimumMergedClusterSize = minimumMergedClusterSize
        self.minimumClusterQuality = minimumClusterQuality
        self.maxIterations = maxIterations
        self.mergeThreshold = mergeThreshold
        self.minimumInternalSimilarity = minimumInternalSimilarity
        self.minimumPairwiseSimilarity = minimumPairwiseSimilarity
    }

    /// AdaFace_IR50(512차원) 기준으로 튜닝된 값 — 기존 FaceClusterService의 상수와 동일
    public static let faceDefault = ClusteringConfig(
        similarityThreshold: 0.64,
        minimumClusterSize: 2,
        minimumMergedClusterSize: 10,
        minimumClusterQuality: 0.50,
        maxIterations: 10,
        mergeThreshold: 0.60,
        minimumInternalSimilarity: 0.10,
        minimumPairwiseSimilarity: 0.10
    )

    /// TODO: 실제 반려동물 사진으로 재튜닝 필요 — DINOv2(384차원) 임베딩 공간의 유사도 분포가
    /// AdaFace(512차원 ArcFace 계열) 얼굴 임베딩과 같으리라는 보장이 없다. 우선 사람 얼굴 기준값을
    /// 그대로 사용해서 시작하고, 실제 데이터로 클러스터링 품질을 보며 조정한다.
    public static let animalDefault = ClusteringConfig(
        similarityThreshold: 0.64,
        minimumClusterSize: 2,
        minimumMergedClusterSize: 10,
        minimumClusterQuality: 0.60,
        maxIterations: 10,
        mergeThreshold: 0.60,
        minimumInternalSimilarity: 0.20,
        minimumPairwiseSimilarity: 0.20
    )
}

// MARK: - ClusterResult

public struct ClusterResult<Item: ClusterableEmbedding> {
    public let embeddings: [Item]
    public let centroid: [Float]
}

// MARK: - ClusteringOutcome

/// `clusterWithLeftoverRetry`의 최종 결과 — 앨범으로 만들 클러스터와, 끝까지 어디에도 못 들어간
/// leftover(다음 전체 재분석 때 처음부터 다시 시도)를 함께 반환한다
public struct ClusteringOutcome<Item: ClusterableEmbedding> {
    public let clusters: [ClusterResult<Item>]
    public let leftover: [Item]
}

// MARK: - ClusteringEngine

public final class ClusteringEngine<Item: ClusterableEmbedding> {

    private let config: ClusteringConfig
    private let logTag: String

    public init(config: ClusteringConfig, logTag: String = "ClusterService") {
        self.config = config
        self.logTag = logTag
    }

    // MARK: - Public

    /// 재시도 없는 단일 패스 — `clusterWithLeftoverRetry(embeddings:maxRetryRounds: 0)`과 동일하다.
    /// 리팩터 전 알고리즘(raw cluster 형성 + 병합을 한 번에)과 결과가 같아야 하는 기존 호출부용.
    public func cluster(embeddings: [Item]) -> [ClusterResult<Item>] {
        clusterWithLeftoverRetry(embeddings: embeddings, maxRetryRounds: 0).clusters
    }

    /// 1) raw cluster 형성 → 2) leftover만 모아 최대 maxRetryRounds회 재시도(새 raw cluster가
    /// 0개인 라운드가 나오면 조기 종료) → 3) 모든 라운드의 raw cluster를 합쳐 최종 병합을 딱 한 번 수행.
    public func clusterWithLeftoverRetry(embeddings: [Item], maxRetryRounds: Int = 3) -> ClusteringOutcome<Item> {
        guard !embeddings.isEmpty else { return ClusteringOutcome(clusters: [], leftover: []) }

        var rawGroups: [[Item]] = []

        let (initialRaw, initialLeftover) = formRawClusters(embeddings: embeddings)
        rawGroups.append(contentsOf: initialRaw)
        var pool = initialLeftover

        var round = 0
        while round < maxRetryRounds, !pool.isEmpty {
            round += 1
            print("🔁 [\(logTag)] leftover 재시도 \(round)차 (입력: \(pool.count)개)")
            let (raw, leftover) = formRawClusters(embeddings: pool)
            guard !raw.isEmpty else {
                print("⏹️ [\(logTag)] 재시도 \(round)차에서 새 raw cluster 없음 — 조기 종료")
                break
            }
            rawGroups.append(contentsOf: raw)
            pool = leftover
        }

        let (clusters, mergeLeftover) = mergeRawClusters(rawGroups)
        let finalLeftover = mergeLeftover + pool

        print("📊 [\(logTag)] 전체 완료 → raw cluster \(rawGroups.count)개 → 최종 클러스터 \(clusters.count)개 / 최종 leftover \(finalLeftover.count)개")
        return ClusteringOutcome(clusters: clusters, leftover: finalLeftover)
    }

    // MARK: - Raw Cluster 형성

    /// Chinese Whispers + 품질/크기 게이트만 수행한다 (아직 최종 크기 병합 전 단계).
    /// 게이트를 통과 못 한 임베딩은 전부 leftover로 모아 반환 — 다음 재시도 라운드의 입력이 된다.
    private func formRawClusters(embeddings: [Item]) -> (raw: [[Item]], leftover: [Item]) {
        let n = embeddings.count
        guard n > 0 else { return ([], []) }

        print("\n--- 🧩 [\(logTag)] raw cluster 형성 (입력: \(n)개, threshold: \(config.similarityThreshold)) ---")

        let similarityMatrix = buildSimilarityMatrix(embeddings: embeddings)
        let photoIds = embeddings.map { $0.photoId }

        let labels = chineseWhispers(n: n, similarityMatrix: similarityMatrix, photoIds: photoIds)

        var groups: [Int: [Int]] = [:]
        for (i, label) in labels.enumerated() {
            groups[label, default: []].append(i)
        }
        print("📊 Chinese Whispers 완료 → \(groups.count)개 그룹")

        var raw: [[Item]] = []
        var leftoverIndices: Set<Int> = []

        for label in groups.keys.sorted() {
            let indices = groups[label]!

            guard indices.count >= config.minimumClusterSize else {
                leftoverIndices.formUnion(indices)
                continue
            }

            let (cleaned, removed) = removeOutliers(indices: indices, n: n, similarityMatrix: similarityMatrix, photoIds: photoIds, minimumSize: config.minimumClusterSize)
            guard cleaned.count >= config.minimumClusterSize else {
                // cleaned + removed == indices — 그룹 전체가 이번 라운드에서 실패
                leftoverIndices.formUnion(indices)
                continue
            }

            let avgSim = averageInternalSimilarity(indices: cleaned, n: n, similarityMatrix: similarityMatrix)
            guard avgSim >= config.minimumClusterQuality else {
                print("⛔️ 품질 낮은 그룹 스킵 (평균 유사도: \(String(format: "%.4f", avgSim)), \(cleaned.count)장)")
                leftoverIndices.formUnion(indices)
                continue
            }

            // 그룹은 성공했지만 도중에 아웃라이어로 잘려나간 개별 포인트는 leftover로
            leftoverIndices.formUnion(removed)
            raw.append(cleaned.map { embeddings[$0] })
        }

        let leftover = leftoverIndices.sorted().map { embeddings[$0] }
        print("📊 [\(logTag)] raw cluster 형성 완료 → \(raw.count)개 / leftover \(leftover.count)개")
        return (raw, leftover)
    }

    // MARK: - Chinese Whispers

    private func chineseWhispers(n: Int, similarityMatrix: [Float], photoIds: [String]) -> [Int] {
        var labels = Array(0..<n)

        var edges: [(i: Int, j: Int, sim: Float)] = []
        for i in 0..<n {
            for j in (i+1)..<n {
                guard photoIds[i] != photoIds[j] else { continue }
                let sim = similarityMatrix[i * n + j]
                if sim >= config.similarityThreshold {
                    edges.append((i, j, sim))
                }
            }
        }

        print("🔗 엣지 수: \(edges.count)개")

        var nodeEdges = Array(repeating: [(idx: Int, sim: Float)](), count: n)
        for edge in edges {
            nodeEdges[edge.i].append((edge.j, edge.sim))
            nodeEdges[edge.j].append((edge.i, edge.sim))
        }

        for iteration in 0..<config.maxIterations {
            var changedCount = 0

            for i in 0..<n {
                guard !nodeEdges[i].isEmpty else { continue }

                var labelWeights: [Int: Float] = [:]
                for (neighbor, sim) in nodeEdges[i] {
                    labelWeights[labels[neighbor], default: 0] += sim
                }

                if let bestLabel = labelWeights.max(by: {
                    $0.value != $1.value ? $0.value < $1.value : $0.key > $1.key
                })?.key {
                    if labels[i] != bestLabel {
                        labels[i] = bestLabel
                        changedCount += 1
                    }
                }
            }

            print("🔄 iteration \(iteration + 1) — changed: \(changedCount)개")
            if changedCount == 0 { break }
        }

        return labels
    }

    // MARK: - Centroid

    private func computeCentroid(embeddings: [Item]) -> [Float] {
        let dim = embeddings[0].embedding.count
        var centroid = [Float](repeating: 0, count: dim)
        for emb in embeddings {
            vDSP_vadd(centroid, 1, emb.embedding, 1, &centroid, 1, vDSP_Length(dim))
        }
        var count = Float(embeddings.count)
        vDSP_vsdiv(centroid, 1, &count, &centroid, 1, vDSP_Length(dim))
        var normSquared: Float = 0
        vDSP_svesq(centroid, 1, &normSquared, vDSP_Length(dim))
        var norm = sqrt(normSquared)
        if norm > 0 { vDSP_vsdiv(centroid, 1, &norm, &centroid, 1, vDSP_Length(dim)) }
        return centroid
    }

    // MARK: - Merge Raw Clusters

    /// raw cluster(형성 라운드가 몇 차든 상관없이 전부 합친 목록)를 centroid 기반으로 병합해
    /// 최종 앨범 후보(`minimumMergedClusterSize` 이상)를 만든다. raw cluster마다 자기 완결적인
    /// `[Item]` 값을 들고 있으므로, 서로 다른 재시도 라운드(다른 임베딩 배열/인덱스 공간)에서 온
    /// raw cluster끼리도 여기서 문제없이 함께 병합될 수 있다.
    private func mergeRawClusters(_ rawGroups: [[Item]]) -> (clusters: [ClusterResult<Item>], leftover: [Item]) {
        let m = rawGroups.count
        guard m > 0 else { return ([], []) }

        if m == 1 {
            let (cleaned, removed) = removeOutliersLocal(items: rawGroups[0], minimumSize: config.minimumMergedClusterSize)
            guard cleaned.count >= config.minimumMergedClusterSize else {
                return ([], rawGroups[0])
            }
            logClusterSummary(cleaned)
            return ([ClusterResult(embeddings: cleaned, centroid: computeCentroid(embeddings: cleaned))], removed)
        }

        let dim = rawGroups[0][0].embedding.count

        let centroids: [[Float]] = rawGroups.map { computeCentroid(embeddings: $0) }

        let centroidFlat = centroids.flatMap { $0 }
        var centroidSim = [Float](repeating: 0, count: m * m)
        centroidFlat.withUnsafeBufferPointer { matPtr in
            centroidSim.withUnsafeMutableBufferPointer { simPtr in
                cblas_sgemm(
                    CblasRowMajor, CblasNoTrans, CblasTrans,
                    Int32(m), Int32(m), Int32(dim),
                    1.0,
                    matPtr.baseAddress!, Int32(dim),
                    matPtr.baseAddress!, Int32(dim),
                    0.0,
                    simPtr.baseAddress!, Int32(m)
                )
            }
        }

        var pairs: [(i: Int, j: Int, sim: Float)] = []
        for i in 0..<m {
            for j in (i+1)..<m {
                let sim = centroidSim[i * m + j]
                if sim >= config.mergeThreshold {
                    pairs.append((i, j, sim))
                }
            }
        }
        pairs.sort { $0.sim > $1.sim }

        var groups: [Int: [Int]] = Dictionary(uniqueKeysWithValues: (0..<m).map { ($0, [$0]) })
        var groupOf = Array(0..<m)

        for pair in pairs {
            let gi = groupOf[pair.i], gj = groupOf[pair.j]
            if gi == gj { continue }
            guard let membersI = groups[gi], let membersJ = groups[gj] else { continue }

            let allPairsQualify = membersI.allSatisfy { a in
                membersJ.allSatisfy { b in centroidSim[a * m + b] >= config.mergeThreshold }
            }
            guard allPairsQualify else { continue }

            let combined = membersI + membersJ
            groups[gi] = combined
            groups.removeValue(forKey: gj)
            for idx in combined { groupOf[idx] = gi }
            print("🔀 [\(logTag)] raw cluster 병합 확정 (클리크 검증 통과, centroid 유사도: \(String(format: "%.4f", pair.sim)))")
        }

        var finalClusters: [ClusterResult<Item>] = []
        var leftover: [Item] = []

        for root in groups.keys.sorted() {
            let members = groups[root]!
            let combinedItems = members.flatMap { rawGroups[$0] }
            let (cleaned, removed) = removeOutliersLocal(items: combinedItems, minimumSize: config.minimumMergedClusterSize)
            if cleaned.count >= config.minimumMergedClusterSize {
                logClusterSummary(cleaned)
                finalClusters.append(ClusterResult(embeddings: cleaned, centroid: computeCentroid(embeddings: cleaned)))
                leftover.append(contentsOf: removed)
            } else {
                leftover.append(contentsOf: combinedItems)
            }
        }

        return (finalClusters, leftover)
    }

    private func logClusterSummary(_ items: [Item]) {
        guard items.count > 1 else {
            print("✅ [\(logTag)] 클러스터 \(items.count)장")
            return
        }
        let matrix = buildSimilarityMatrix(embeddings: items)
        let n = items.count
        var minSim: Float = 2, maxSim: Float = -2, total: Float = 0, count = 0
        for i in 0..<n {
            for j in (i+1)..<n {
                let sim = matrix[i * n + j]
                minSim = min(minSim, sim)
                maxSim = max(maxSim, sim)
                total += sim
                count += 1
            }
        }
        let avgSim = count > 0 ? total / Float(count) : 0
        print("✅ [\(logTag)] 클러스터 \(items.count)장 (내부 유사도 min: \(String(format: "%.3f", minSim)), avg: \(String(format: "%.3f", avgSim)), max: \(String(format: "%.3f", maxSim)))")
    }

    /// 공유 유사도 행렬 없이 독립적인 `[Item]` 그룹에 대해 아웃라이어를 제거한다 — 로컬 유사도
    /// 행렬을 그 그룹만으로 새로 계산해서 기존 `removeOutliers`(인덱스 기반)에 그대로 위임한다.
    private func removeOutliersLocal(items: [Item], minimumSize: Int) -> (kept: [Item], removed: [Item]) {
        guard !items.isEmpty else { return ([], []) }
        let n = items.count
        let similarityMatrix = buildSimilarityMatrix(embeddings: items)
        let photoIds = items.map { $0.photoId }
        let (keptIdx, removedIdx) = removeOutliers(indices: Array(0..<n), n: n, similarityMatrix: similarityMatrix, photoIds: photoIds, minimumSize: minimumSize)
        return (keptIdx.map { items[$0] }, removedIdx.map { items[$0] })
    }

    private func removeOutliers(indices: [Int], n: Int, similarityMatrix: [Float], photoIds: [String], minimumSize: Int) -> (kept: [Int], removed: [Int]) {
        var current = indices
        var removed: [Int] = []

        while current.count >= minimumSize {
            let denominator = Float(current.count - 1)
            guard denominator > 0 else { break }

            if let dupOut = worstDuplicatePhotoPoint(in: current, n: n, similarityMatrix: similarityMatrix, photoIds: photoIds) {
                current.removeAll { $0 == dupOut }
                removed.append(dupOut)
                continue
            }

            var filtered: [Int] = []

            for i in 0..<current.count {
                let idxA = current[i]
                var totalSim: Float = 0
                for j in 0..<current.count where i != j {
                    totalSim += similarityMatrix[idxA * n + current[j]]
                }
                if totalSim / denominator >= config.minimumInternalSimilarity {
                    filtered.append(idxA)
                }
            }

            if filtered.count == current.count {
                guard let worst = worstPairwisePoint(in: current, n: n, similarityMatrix: similarityMatrix) else {
                    break
                }
                current.removeAll { $0 == worst }
                removed.append(worst)
                continue
            }
            let filteredSet = Set(filtered)
            removed.append(contentsOf: current.filter { !filteredSet.contains($0) })
            current = filtered
        }

        return (current, removed)
    }

    private func worstPairwisePoint(in indices: [Int], n: Int, similarityMatrix: [Float]) -> Int? {
        var worstIdx: Int?
        var worstMin: Float = config.minimumPairwiseSimilarity

        for idxA in indices {
            var minSim: Float = 1.0
            for idxB in indices where idxB != idxA {
                minSim = min(minSim, similarityMatrix[idxA * n + idxB])
            }
            if minSim < worstMin {
                worstMin = minSim
                worstIdx = idxA
            }
        }

        return worstIdx
    }

    private func worstDuplicatePhotoPoint(in indices: [Int], n: Int, similarityMatrix: [Float], photoIds: [String]) -> Int? {
        let grouped = Dictionary(grouping: indices) { photoIds[$0] }
        guard let dupGroup = grouped.values.first(where: { $0.count > 1 }) else { return nil }

        let others = indices.filter { photoIds[$0] != photoIds[dupGroup[0]] }
        guard !others.isEmpty else { return dupGroup[1] }

        var worstIdx = dupGroup[0]
        var worstAvg: Float = .greatestFiniteMagnitude
        for idxA in dupGroup {
            var total: Float = 0
            for idxB in others {
                total += similarityMatrix[idxA * n + idxB]
            }
            let avg = total / Float(others.count)
            if avg < worstAvg {
                worstAvg = avg
                worstIdx = idxA
            }
        }
        return worstIdx
    }

    // MARK: - 품질 검증

    private func averageInternalSimilarity(indices: [Int], n: Int, similarityMatrix: [Float]) -> Float {
        guard indices.count > 1 else { return 1.0 }
        var total: Float = 0
        var count = 0
        for i in 0..<indices.count {
            for j in (i+1)..<indices.count {
                total += similarityMatrix[indices[i] * n + indices[j]]
                count += 1
            }
        }
        return count > 0 ? total / Float(count) : 0
    }

    // MARK: - Similarity Matrix

    private func buildSimilarityMatrix(embeddings: [Item]) -> [Float] {
        let n = embeddings.count
        let dim = embeddings[0].embedding.count
        let flatMatrix = embeddings.flatMap { $0.embedding }

        var similarityMatrix = [Float](repeating: 0, count: n * n)
        flatMatrix.withUnsafeBufferPointer { matPtr in
            similarityMatrix.withUnsafeMutableBufferPointer { simPtr in
                cblas_sgemm(
                    CblasRowMajor, CblasNoTrans, CblasTrans,
                    Int32(n), Int32(n), Int32(dim),
                    1.0,
                    matPtr.baseAddress!, Int32(dim),
                    matPtr.baseAddress!, Int32(dim),
                    0.0,
                    simPtr.baseAddress!, Int32(n)
                )
            }
        }
        return similarityMatrix
    }
}
