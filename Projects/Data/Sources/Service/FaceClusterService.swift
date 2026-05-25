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

public final class FaceClusterService {
    
    private let threshold: Float = 0.82
    private let minimumClusterSize: Int = 3
    private let minimumInternalSimilarity: Float = 0.7
    private let mergeThreshold: Float = 0.75

    public init() { }

    public func cluster(embeddings: [FaceEmbedding]) -> [(FaceEmbedding, String)] {
        print("\n--- 🧠 [ClusterService] 그래프 기반 클러스터링 시작 (입력: \(embeddings.count)개, threshold: \(threshold)) ---")
        
        let n = embeddings.count
        guard n > 0 else { return [] }
        
        let (adjacency, similarityMatrix) = buildAdjacencyAndMatrix(embeddings: embeddings)
        let edgeCount = adjacency.reduce(0) { $0 + $1.count } / 2
        print("🔗 [ClusterService] 확실한 쌍 \(edgeCount)개 연결됨")
        
        var parent = Array(0..<n)
        
        func find(_ x: Int) -> Int {
            if parent[x] != x { parent[x] = find(parent[x]) }
            return parent[x]
        }
        
        func union(_ x: Int, _ y: Int) {
            let px = find(x), py = find(y)
            if px != py { parent[px] = py }
        }
        
        for i in 0..<n {
            for j in adjacency[i] { union(i, j) }
        }
        
        var components: [Int: [Int]] = [:]
        for i in 0..<n {
            guard !adjacency[i].isEmpty else { continue }
            components[find(i), default: []].append(i)
        }
        
        // outlier 제거까지 완료된 클러스터 배열
        var validIndicesList: [[Int]] = []
        var skippedSize = 0
        
        for (_, indices) in components {
            guard indices.count >= minimumClusterSize else {
                skippedSize += 1
                continue
            }
            let cleaned = removeOutliers(indices: indices, n: n, similarityMatrix: similarityMatrix)
            guard cleaned.count >= minimumClusterSize else {
                print("⛔️ outlier 제거 후 \(cleaned.count)장 남음 (원래 \(indices.count)장) -> 스킵")
                skippedSize += 1
                continue
            }
            validIndicesList.append(cleaned)
        }
        
        // 클러스터 간 병합
        let mergedList = mergeClusters(
            clusterEmbeddingIndices: validIndicesList,
            embeddings: embeddings,
            n: n,
            similarityMatrix: similarityMatrix
        )
        
        var results: [(FaceEmbedding, String)] = []
        var personIndex = 1
        var validClusters = 0
        
        for indices in mergedList {
            guard indices.count >= minimumClusterSize else { continue }
            
            let clusterId = "인물 \(personIndex)"
            personIndex += 1
            validClusters += 1
            
            for idx in indices {
                results.append((embeddings[idx], clusterId))
            }
            print("✅ [\(clusterId)] \(indices.count)장")
        }
        
        print("📊 [ClusterService] 완료 -> 유효: \(validClusters)개 / 스킵: \(skippedSize)개")
        print("-----------------------------------------------------------------------------------------\n")
        return results
    }

    // MARK: - Private

    private func buildAdjacencyAndMatrix(embeddings: [FaceEmbedding]) -> (adjacency: [[Int]], matrix: [Float]) {
        let n = embeddings.count
        let dim = embeddings[0].embedding.count
        let flatMatrix = embeddings.flatMap { $0.embedding }
        
        var similarityMatrix = [Float](repeating: 0, count: n * n)
        flatMatrix.withUnsafeBufferPointer { matPtr in
            similarityMatrix.withUnsafeMutableBufferPointer { simPtr in
                cblas_sgemm(
                    CblasRowMajor,
                    CblasNoTrans,
                    CblasTrans,
                    Int32(n), Int32(n), Int32(dim),
                    1.0,
                    matPtr.baseAddress!, Int32(dim),
                    matPtr.baseAddress!, Int32(dim),
                    0.0,
                    simPtr.baseAddress!, Int32(n)
                )
            }
        }
        
        var adjacency = Array(repeating: [Int](), count: n)
        for i in 0..<n {
            for j in (i+1)..<n {
                if similarityMatrix[i * n + j] >= threshold {
                    adjacency[i].append(j)
                    adjacency[j].append(i)
                }
            }
        }
        return (adjacency, similarityMatrix)
    }

    private func removeOutliers(indices: [Int], n: Int, similarityMatrix: [Float]) -> [Int] {
        guard indices.count > 1 else { return indices }
        
        var current = indices
        
        while true {
            guard current.count > 1 else { break }
            
            let denominator = Float(current.count - 1)
            var filtered: [Int] = []
            
            for i in 0..<current.count {
                let idxA = current[i]
                var totalSim: Float = 0
                
                for j in 0..<current.count where i != j {
                    totalSim += similarityMatrix[idxA * n + current[j]]
                }
                
                let avgSim = totalSim / denominator
                if avgSim >= minimumInternalSimilarity {
                    filtered.append(idxA)
                }
            }
            
            if filtered.count == current.count { break }
            current = filtered
        }
        
        return current
    }

    private func mergeClusters(
        clusterEmbeddingIndices: [[Int]],
        embeddings: [FaceEmbedding],
        n: Int,
        similarityMatrix: [Float]
    ) -> [[Int]] {
        let m = clusterEmbeddingIndices.count
        guard m > 1 else { return clusterEmbeddingIndices }
        
        let dim = embeddings[0].embedding.count
        
        // 1. 각 클러스터의 centroid 계산
        var centroids: [[Float]] = clusterEmbeddingIndices.map { indices in
            var centroid = [Float](repeating: 0, count: dim)
            for idx in indices {
                let emb = embeddings[idx].embedding
                vDSP_vadd(centroid, 1, emb, 1, &centroid, 1, vDSP_Length(dim))
            }
            var count = Float(indices.count)
            vDSP_vsdiv(centroid, 1, &count, &centroid, 1, vDSP_Length(dim))
            
            // L2 정규화
            var normSquared: Float = 0
            vDSP_svesq(centroid, 1, &normSquared, vDSP_Length(dim))
            var norm = sqrt(normSquared)
            if norm > 0 {
                vDSP_vsdiv(centroid, 1, &norm, &centroid, 1, vDSP_Length(dim))
            }
            return centroid
        }
        
        // 2. centroid 간 유사도 행렬 계산
        let centroidFlat = centroids.flatMap { $0 }
        var centroidSimilarity = [Float](repeating: 0, count: m * m)
        
        centroidFlat.withUnsafeBufferPointer { matPtr in
            centroidSimilarity.withUnsafeMutableBufferPointer { simPtr in
                cblas_sgemm(
                    CblasRowMajor,
                    CblasNoTrans,
                    CblasTrans,
                    Int32(m), Int32(m), Int32(dim),
                    1.0,
                    matPtr.baseAddress!, Int32(dim),
                    matPtr.baseAddress!, Int32(dim),
                    0.0,
                    simPtr.baseAddress!, Int32(m)
                )
            }
        }
        
        // 3. 유사도 높은 순으로 정렬 후 병합 시도
        var pairs: [(i: Int, j: Int, sim: Float)] = []
        for i in 0..<m {
            for j in (i+1)..<m {
                let sim = centroidSimilarity[i * m + j]
                if sim >= mergeThreshold {
                    pairs.append((i, j, sim))
                }
            }
        }
        pairs.sort { $0.sim > $1.sim }
        
        var parent = Array(0..<m)
        
        func find(_ x: Int) -> Int {
            var x = x
            while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x] }
            return x
        }
        
        for pair in pairs {
            let pi = find(pair.i)
            let pj = find(pair.j)
            guard pi != pj else { continue }
            
            // 병합 후보 인덱스 합치기
            var mergedIndices: [Int] = []
            for k in 0..<m {
                if find(k) == pi || find(k) == pj {
                    mergedIndices.append(contentsOf: clusterEmbeddingIndices[k])
                }
            }
            
            // 내부 품질 체크
            let cleaned = removeOutliers(indices: mergedIndices, n: n, similarityMatrix: similarityMatrix)
            guard cleaned.count >= minimumClusterSize else { continue }
            
            // 품질 통과하면 병합
            parent[pi] = pj
            print("🔀 클러스터 병합 (유사도: \(String(format: "%.4f", pair.sim)))")
        }
        
        // 4. 병합 결과 그룹핑
        var merged: [Int: [Int]] = [:]
        for i in 0..<m {
            merged[find(i), default: []].append(contentsOf: clusterEmbeddingIndices[i])
        }
        
        return Array(merged.values)
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        var result: Float = 0
        vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result
    }
}
