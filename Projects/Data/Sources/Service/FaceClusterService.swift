//
//  FaceClusterService.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import Foundation
import Accelerate
import UIKit

// MARK: - ClusterResult

public struct ClusterResult {
    public let embeddings: [FaceEmbedding]
    public let centroid: [Float]
}

// MARK: - FaceClusterService

public final class FaceClusterService {

    // MARK: - Parameters

    // AdaFace_IR50으로 모델 교체 — InsightFace_buffalo_l 기준으로 튜닝된 값들이라 전체적으로 낮춰서 다시 검증 필요

    /// 이웃 판단 기준 — 이 값 이상이면 엣지 연결
    private let similarityThreshold: Float = 0.82

    /// 최소 클러스터 크기
    private let minimumClusterSize: Int = 3

    /// 개별 클러스터 품질 기준 — 이 미만이면 짜투리로 버림
    private let minimumClusterQuality: Float = 0.78

    /// Chinese Whispers 반복 횟수
    private let maxIterations: Int = 50

    /// 클러스터 병합 기준 — centroid 간 유사도
    private let mergeThreshold: Float = 0.80

    /// 병합 후 내부 유사도 검증 기준 (평균 기준 — 한 쌍만 유독 낮아도 다른 멤버들과 평균이 높으면 통과될 수 있음)
    private let minimumInternalSimilarity: Float = 0.80

    /// 평균이 기준을 넘어도, 다른 멤버 중 단 한 명과의 유사도라도 이 값 미만이면 그 얼굴을 아웃라이어로 판단
    private let minimumPairwiseSimilarity: Float = 0.76

    private let libraryService: PhotoLibraryService

    public init(libraryService: PhotoLibraryService) {
        self.libraryService = libraryService
    }

    private var debugSaveCount = 0

    private func save(id: String, boundingBox: CGRect) async throws {
        if let image = try await loadImage(photoId: id) {
            self.saveDebugCrop(image, boundingBox: boundingBox)
        }
    }

    private func saveDebugCrop(_ image: CGImage, boundingBox: CGRect) {
        guard debugSaveCount < 20 else { return }
        guard let cropped = cropFace(from: image, boundingBox: boundingBox) else { return }
        let uiImage = UIImage(cgImage: cropped)
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        debugSaveCount += 1
    }

    private func cropFace(from image: CGImage, boundingBox: CGRect) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        let scale: CGFloat = 1.1
        let expandedWidth = boundingBox.width * scale
        let expandedHeight = boundingBox.height * scale
        let expandedX = boundingBox.minX - (expandedWidth - boundingBox.width) / 2
        let expandedY = boundingBox.minY - (expandedHeight - boundingBox.height) / 2

        let clampedX = max(0, expandedX)
        let clampedY = max(0, expandedY)
        let clampedWidth = min(expandedWidth, 1.0 - clampedX)
        let clampedHeight = min(expandedHeight, 1.0 - clampedY)

        let rect = CGRect(
            x: clampedX * width,
            y: (1.0 - clampedY - clampedHeight) * height,
            width: clampedWidth * width,
            height: clampedHeight * height
        )
        return image.cropping(to: rect)
    }

    private func loadImage(photoId: String, size: CGFloat = 1024) async throws -> CGImage? {
        try await libraryService.loadImage(
            id: photoId,
            type: .specialSize(CGSize(width: size, height: size))
        )
    }

    // MARK: - Public

    public func cluster(embeddings: [FaceEmbedding]) -> [ClusterResult] {
        let n = embeddings.count
        guard n > 0 else { return [] }

        print("\n--- 🧠 [ClusterService] Chinese Whispers 클러스터링 시작 (입력: \(n)개, threshold: \(similarityThreshold)) ---")

        // 1. 유사도 행렬 계산
        let similarityMatrix = buildSimilarityMatrix(embeddings: embeddings)
        let photoIds = embeddings.map { $0.photoId }

        // 2. Chinese Whispers
        let labels = chineseWhispers(n: n, similarityMatrix: similarityMatrix, photoIds: photoIds)

        // 3. 레이블별 그룹핑 (노이즈 개념 없음 — 전부 유효)
        var groups: [Int: [Int]] = [:]
        for (i, label) in labels.enumerated() {
            groups[label, default: []].append(i)
        }

        print("📊 Chinese Whispers 완료 → \(groups.count)개 클러스터")

        // 4. 개별 클러스터 품질 검증 — 짜투리 제거
        var qualityPassedList: [[Int]] = []
        var skipped = 0

        for label in groups.keys.sorted() {
            let indices = groups[label]!

            guard indices.count >= minimumClusterSize else {
                skipped += 1
                continue
            }

            // 평균을 심하게 깎아먹는 애를 먼저 제거해보고, 남은 애들 기준으로 품질을 재평가한다.
            // (그냥 평균만 보면 나머지는 멀쩡한데 1명 때문에 그룹 전체가 통째로 버려질 수 있음)
            let cleaned = removeOutliers(indices: indices, n: n, similarityMatrix: similarityMatrix, photoIds: photoIds)
            guard cleaned.count >= minimumClusterSize else {
                skipped += 1
                continue
            }

            let avgSim = averageInternalSimilarity(indices: cleaned, n: n, similarityMatrix: similarityMatrix)
            guard avgSim >= minimumClusterQuality else {
                print("⛔️ 품질 낮은 클러스터 스킵 (평균 유사도: \(String(format: "%.4f", avgSim)), \(cleaned.count)장)")
                skipped += 1
                continue
            }

            qualityPassedList.append(cleaned)
        }

        print("📊 품질 검증 완료 → \(qualityPassedList.count)개 통과 / \(skipped)개 스킵")

        // 5. centroid 기반 병합
        let mergedList = mergeClusters(
            clusterIndices: qualityPassedList,
            embeddings: embeddings,
            n: n,
            similarityMatrix: similarityMatrix,
            photoIds: photoIds
        )

        // 6. 결과 조립
        var results: [ClusterResult] = []
        var finalSkipped = 0

        for indices in mergedList {
            guard indices.count >= minimumClusterSize else {
                finalSkipped += 1
                continue
            }

            let clusterEmbeddings = indices.map { embeddings[$0] }
            let centroid = computeCentroid(embeddings: clusterEmbeddings)
            results.append(ClusterResult(embeddings: clusterEmbeddings, centroid: centroid))

            // 진단용 — 정말 같은 사람끼리 묶였는지 확인하려고, 클러스터 내부 쌍의 min/avg/max 유사도와
            // 실제 사진 id를 같이 찍는다. min이 유독 낮으면 그 안에 다른 사람이 섞여있다는 뜻이고,
            // 반대로 서로 다른 클러스터인데 avg가 낮다면 원래 같은 사람인데 임베딩이 갈라진 것일 수 있다.
            // 특히 min을 만든 "그 두 장"의 photoId를 따로 찍어서, 설정을 바꿔가며 재분석해도
            // 같은 쌍의 유사도 숫자만 비교하면 되도록 한다 (전체 클러스터 크기 비교보다 훨씬 명확함)
            var pairSimilarities: [Float] = []
            var minSim: Float = 2
            var minPair: (String, String)?
            var maxSim: Float = -2
            for i in 0..<indices.count {
                for j in (i + 1)..<indices.count {
                    let sim = similarityMatrix[indices[i] * n + indices[j]]
                    pairSimilarities.append(sim)
                    if sim < minSim {
                        minSim = sim
                        minPair = (embeddings[indices[i]].photoId, embeddings[indices[j]].photoId)
                    }
                    maxSim = max(maxSim, sim)
                }
            }
            let simSummary: String
            if !pairSimilarities.isEmpty {
                let avgSim = pairSimilarities.reduce(0, +) / Float(pairSimilarities.count)
                simSummary = String(format: "min: %.3f, avg: %.3f, max: %.3f", minSim, avgSim, maxSim)
            } else {
                simSummary = "쌍 없음"
            }
            print("✅ [클러스터] \(clusterEmbeddings.count)장 (내부 유사도 \(simSummary))")
            if let minPair {
                print("   ⚠️ 최소 유사도 쌍: \(minPair.0) <-> \(minPair.1)")
            }

            // 진단용 — "그 쌍"이 아니라 "나머지 전체랑 비교했을 때 진짜 겉도는 애"를 찾기 위한 멤버별 평균.
            // 낮은 순으로 정렬해서 맨 위에 오는 사진이 이 클러스터에서 가장 안 어울리는 후보다.
            let denom = Float(max(indices.count - 1, 1))
            let perMemberAverages: [(String, Float)] = indices.map { idxA in
                var total: Float = 0
                for idxB in indices where idxB != idxA {
                    total += similarityMatrix[idxA * n + idxB]
                }
                return (embeddings[idxA].photoId, total / denom)
            }.sorted { $0.1 < $1.1 }

            print("   멤버별 평균 유사도(낮은 순):")
            for (photoId, avg) in perMemberAverages {
                print("      \(String(format: "%.3f", avg)) — \(photoId)")
            }

            print("   photoIds: \(clusterEmbeddings.map { $0.photoId })")
        }

        print("📊 [ClusterService] 완료 → 유효: \(results.count)개 / 스킵: \(skipped + finalSkipped)개")
        print("-----------------------------------------------------------------------------------------\n")
        return results
    }

    // MARK: - Chinese Whispers

    private func chineseWhispers(n: Int, similarityMatrix: [Float], photoIds: [String]) -> [Int] {
        var labels = Array(0..<n)

        // threshold 이상인 엣지만 추출 — 단, 같은 사진에서 나온 서로 다른 얼굴은 무조건 다른 사람이므로 연결하지 않는다
        var edges: [(i: Int, j: Int, sim: Float)] = []
        for i in 0..<n {
            for j in (i+1)..<n {
                guard photoIds[i] != photoIds[j] else { continue }
                let sim = similarityMatrix[i * n + j]
                if sim >= similarityThreshold {
                    edges.append((i, j, sim))
                }
            }
        }

        print("🔗 엣지 수: \(edges.count)개")

        // 노드별 엣지 인덱스 빠른 조회용
        var nodeEdges = Array(repeating: [(idx: Int, sim: Float)](), count: n)
        for edge in edges {
            nodeEdges[edge.i].append((edge.j, edge.sim))
            nodeEdges[edge.j].append((edge.i, edge.sim))
        }

        // 반복 — 같은 입력이면 항상 같은 결과가 나오도록 순회 순서와 동점 처리를 모두 고정한다.
        // (기존엔 .shuffled()로 매번 순서가 달랐고, 가중치 동점일 때 Dictionary.max(by:)가
        // 프로세스마다 랜덤한 해시 순서에 의존해서 실행할 때마다 결과가 미묘하게 달라졌었다)
        for iteration in 0..<maxIterations {
            var changed = false

            for i in 0..<n {
                guard !nodeEdges[i].isEmpty else { continue }

                // 이웃 레이블별 가중치 합산
                var labelWeights: [Int: Float] = [:]
                for (neighbor, sim) in nodeEdges[i] {
                    labelWeights[labels[neighbor], default: 0] += sim
                }

                // 가장 가중치 높은 레이블로 교체 — 가중치가 같으면 레이블 번호가 작은 쪽으로 고정
                if let bestLabel = labelWeights.max(by: {
                    $0.value != $1.value ? $0.value < $1.value : $0.key > $1.key
                })?.key {
                    if labels[i] != bestLabel {
                        labels[i] = bestLabel
                        changed = true
                    }
                }
            }

            print("🔄 iteration \(iteration + 1) — changed: \(changed)")
            if !changed { break }
        }

        return labels
    }

    // MARK: - Centroid

    private func computeCentroid(embeddings: [FaceEmbedding]) -> [Float] {
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

    // MARK: - Merge Clusters

        private func mergeClusters(
            clusterIndices: [[Int]],
            embeddings: [FaceEmbedding],
            n: Int,
            similarityMatrix: [Float],
            photoIds: [String]
        ) -> [[Int]] {
            let m = clusterIndices.count
            guard m > 1 else {
                return clusterIndices.map { removeOutliers(indices: $0, n: n, similarityMatrix: similarityMatrix, photoIds: photoIds) }
            }

            let dim = embeddings[0].embedding.count

            // 1. 각 클러스터의 Centroid(중심점) 계산
            let centroids: [[Float]] = clusterIndices.map { indices in
                var centroid = [Float](repeating: 0, count: dim)
                for idx in indices {
                    let emb = embeddings[idx].embedding
                    vDSP_vadd(centroid, 1, emb, 1, &centroid, 1, vDSP_Length(dim))
                }
                var count = Float(indices.count)
                vDSP_vsdiv(centroid, 1, &count, &centroid, 1, vDSP_Length(dim))
                var normSquared: Float = 0
                vDSP_svesq(centroid, 1, &normSquared, vDSP_Length(dim))
                var norm = sqrt(normSquared)
                if norm > 0 { vDSP_vsdiv(centroid, 1, &norm, &centroid, 1, vDSP_Length(dim)) }
                return centroid
            }

            // 2. Centroid 간의 유사도 행렬 계산
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

            // 3. 유사도 기준을 만족하는 pairs 생성 및 정렬
            var pairs: [(i: Int, j: Int, sim: Float)] = []
            for i in 0..<m {
                for j in (i+1)..<m {
                    let sim = centroidSim[i * m + j]
                    if sim >= mergeThreshold {
                        pairs.append((i, j, sim))
                    }
                }
            }
            pairs.sort { $0.sim > $1.sim }

            // 4. 클리크(완전 연결) 기준으로만 병합 — Union-Find로 체인(A-B, B-C 각각 통과) 병합하면
            // A-C는 직접 비교했을 때 기준 미달이어도 B를 다리 삼아 강제로 한 그룹이 되어버린다.
            // 그래서 두 그룹을 합칠 땐 양쪽 그룹에 속한 "모든" 클러스터 쌍이 전부 mergeThreshold를 넘을 때만 합친다.
            var groups: [Int: [Int]] = Dictionary(uniqueKeysWithValues: (0..<m).map { ($0, [$0]) })
            var groupOf = Array(0..<m)

            for pair in pairs {
                let gi = groupOf[pair.i], gj = groupOf[pair.j]
                if gi == gj { continue }
                guard let membersI = groups[gi], let membersJ = groups[gj] else { continue }

                let allPairsQualify = membersI.allSatisfy { a in
                    membersJ.allSatisfy { b in centroidSim[a * m + b] >= mergeThreshold }
                }
                guard allPairsQualify else { continue }

                let combined = membersI + membersJ
                groups[gi] = combined
                groups.removeValue(forKey: gj)
                for idx in combined { groupOf[idx] = gi }
                print("🔀 클러스터 병합 확정 (클리크 검증 통과, centroid 유사도: \(String(format: "%.4f", pair.sim)))")
            }

            // 5. 최종 그룹별로 실제 사진 인덱스 수집
            var merged: [Int: [Int]] = [:]
            for (root, members) in groups {
                merged[root] = members.flatMap { clusterIndices[$0] }
            }

            // 6. 최종 그룹 내부의 아웃라이어(엉뚱한 사람) 제거 및 최소 크기 검증
            var finalClusters: [[Int]] = []
            for indices in merged.values {
                let cleaned = removeOutliers(indices: indices, n: n, similarityMatrix: similarityMatrix, photoIds: photoIds)
                if cleaned.count >= minimumClusterSize {
                    finalClusters.append(cleaned)
                }
            }

            return finalClusters
        }


    private func removeOutliers(indices: [Int], n: Int, similarityMatrix: [Float], photoIds: [String]) -> [Int] {
        var current = indices

        while current.count >= minimumClusterSize { // 최소 크기 미만으로 떨어지면 어차피 탈락이므로 탈출
            let denominator = Float(current.count - 1)
            guard denominator > 0 else { break } // 0 나누기 방지 안전장치

            // 같은 사진에서 나온 서로 다른 얼굴은 무조건 다른 사람 — 체인 병합으로 한 클러스터에 같이 들어왔다면
            // 그 사진 속 얼굴들 중 이 그룹과 가장 안 닮은(평균 유사도 낮은) 쪽부터 제거한다
            if let dupOut = worstDuplicatePhotoPoint(in: current, n: n, similarityMatrix: similarityMatrix, photoIds: photoIds) {
                current.removeAll { $0 == dupOut }
                continue
            }

            var filtered: [Int] = []

            for i in 0..<current.count {
                let idxA = current[i]
                var totalSim: Float = 0
                for j in 0..<current.count where i != j {
                    totalSim += similarityMatrix[idxA * n + current[j]]
                }
                if totalSim / denominator >= minimumInternalSimilarity {
                    filtered.append(idxA)
                }
            }

            if filtered.count == current.count {
                // 평균 기준은 다 통과했지만, 특정 멤버 단 한 명과의 유사도만 유독 낮은 경우를 놓칠 수 있다
                // (다른 멤버들과는 평균이 높아서 살아남는 경우) — 그래서 최소 pairwise 유사도도 별도로 확인
                guard let worst = worstPairwisePoint(in: current, n: n, similarityMatrix: similarityMatrix) else {
                    break
                }
                current.removeAll { $0 == worst }
                continue
            }
            current = filtered
        }

        return current
    }

    // 그룹 안에서 "다른 멤버 중 단 한 명과의 유사도"라도 minimumPairwiseSimilarity 미만인 얼굴 중,
    // 그 최소값이 가장 낮은(=가장 안 닮은 쌍을 만든) 얼굴 하나를 골라 반환한다.
    private func worstPairwisePoint(in indices: [Int], n: Int, similarityMatrix: [Float]) -> Int? {
        var worstIdx: Int?
        var worstMin: Float = minimumPairwiseSimilarity

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

    // 같은 photoId(같은 사진)에서 나온 얼굴이 그룹 안에 2개 이상 있으면 무조건 서로 다른 사람이 섞인 것이다.
    // 그 중 이 그룹(자기 사진 속 나머지는 제외)과의 평균 유사도가 가장 낮은 하나를 제거 대상으로 반환한다.
    private func worstDuplicatePhotoPoint(in indices: [Int], n: Int, similarityMatrix: [Float], photoIds: [String]) -> Int? {
        let grouped = Dictionary(grouping: indices) { photoIds[$0] }
        guard let dupGroup = grouped.values.first(where: { $0.count > 1 }) else { return nil }

        let others = indices.filter { photoIds[$0] != photoIds[dupGroup[0]] }
        guard !others.isEmpty else { return dupGroup[1] } // 그룹 전체가 한 사진뿐이면 그냥 하나 제거

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

    private func buildSimilarityMatrix(embeddings: [FaceEmbedding]) -> [Float] {
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
