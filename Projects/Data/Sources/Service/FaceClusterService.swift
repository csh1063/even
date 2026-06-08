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

public final class FaceClusterService {
    
    // MARK: - Parameters
    
    /// DBSCAN 이웃 판단 기준
    private let similarityThreshold: Float = 0.80
    
    /// 코어 포인트 최소 이웃 수
    private let minPts: Int = 3
    
    /// 최소 클러스터 크기
    private let minimumClusterSize: Int = 3
    
    /// 개별 클러스터 품질 기준 — 이 미만이면 짜투리로 판단하여 버림
    private let minimumClusterQuality: Float = 0.74
    
    /// 클러스터 병합 기준 — centroid 간 유사도 (낮게)
    private let mergeThreshold: Float = 0.70
    
    /// 병합 후 내부 유사도 검증 기준 (중간)
    private let minimumInternalSimilarity: Float = 0.78
    
    
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
        
        // 이미지 경계 벗어나지 않도록 클램핑
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
    
    public func cluster(embeddings: [FaceEmbedding]) -> [(FaceEmbedding, String)] {
        let n = embeddings.count
        guard n > 0 else { return [] }
        
        print("\n--- 🧠 [ClusterService] DBSCAN 클러스터링 시작 (입력: \(n)개, threshold: \(similarityThreshold), minPts: \(minPts)) ---")
        
        // 1. 유사도 행렬 계산
        let similarityMatrix = buildSimilarityMatrix(embeddings: embeddings)
        
        // 2. DBSCAN
        let labels = dbscan(n: n, similarityMatrix: similarityMatrix)
        
        // 3. 레이블별 그룹핑
        var groups: [Int: [Int]] = [:]
        for (i, label) in labels.enumerated() {
            guard label >= 0 else { continue }
            groups[label, default: []].append(i)
        }
        
        print("📊 DBSCAN 완료 → \(groups.count)개 클러스터 / 노이즈: \(labels.filter { $0 == -1 }.count)개")
        
        // 4. 개별 클러스터 품질 검증 — 짜투리 제거
        var qualityPassedList: [[Int]] = []
        var skipped = 0
        
        for label in groups.keys.sorted() {
            let indices = groups[label]!
            
            guard indices.count >= minimumClusterSize else {
                skipped += 1
                continue
            }
            
            let avgSim = averageInternalSimilarity(indices: indices, n: n, similarityMatrix: similarityMatrix)
            guard avgSim >= minimumClusterQuality else {
                print("⛔️ 품질 낮은 클러스터 스킵 (평균 유사도: \(String(format: "%.4f", avgSim)), \(indices.count)장)")
                skipped += 1
                continue
            }
            
            qualityPassedList.append(indices)
        }
        
        print("📊 품질 검증 완료 → \(qualityPassedList.count)개 통과 / \(skipped)개 스킵")
        
        // 5. centroid 기반 병합 — 품질 통과한 클러스터끼리만
        let mergedList = mergeClusters(
            clusterIndices: qualityPassedList,
            embeddings: embeddings,
            n: n,
            similarityMatrix: similarityMatrix
        )
        
        // 6. 결과 조립
        var results: [(FaceEmbedding, String)] = []
        var personIndex = 1
        var finalSkipped = 0
        
        for indices in mergedList {
            guard indices.count >= minimumClusterSize else {
                finalSkipped += 1
                continue
            }
            
            let clusterId = "인물 \(personIndex)"
            personIndex += 1
            
            for idx in indices {
                results.append((embeddings[idx], clusterId))
            }
            print("✅ [\(clusterId)] \(indices.count)장")
        }
        
        let noiseCount = labels.filter { $0 == -1 }.count
        print("📊 [ClusterService] 완료 → 유효: \(personIndex - 1)개 / 스킵: \(skipped + finalSkipped)개 / 노이즈: \(noiseCount)개")
        print("-----------------------------------------------------------------------------------------\n")
        return results
    }
    
    // MARK: - DBSCAN
    
    private func dbscan(n: Int, similarityMatrix: [Float]) -> [Int] {
        var labels = Array(repeating: -2, count: n)
        var clusterID = 0
        
        for i in 0..<n {
            guard labels[i] == -2 else { continue }
            
            let neighbors = regionQuery(i, n: n, similarityMatrix: similarityMatrix)
            
            if neighbors.count < minPts {
                labels[i] = -1
                continue
            }
            
            labels[i] = clusterID
            var seeds = Set(neighbors)
            seeds.remove(i)
            
            while !seeds.isEmpty {
                let j = seeds.removeFirst()
                
                if labels[j] == -1 { labels[j] = clusterID }
                guard labels[j] == -2 else { continue }
                
                labels[j] = clusterID
                
                let jNeighbors = regionQuery(j, n: n, similarityMatrix: similarityMatrix)
                if jNeighbors.count >= minPts {
                    for neighbor in jNeighbors where labels[neighbor] == -2 || labels[neighbor] == -1 {
                        seeds.insert(neighbor)
                    }
                }
            }
            
            clusterID += 1
        }
        
        return labels
    }
    
    private func regionQuery(_ idx: Int, n: Int, similarityMatrix: [Float]) -> [Int] {
        let row = idx * n
        return (0..<n).filter { similarityMatrix[row + $0] >= similarityThreshold }
    }
    
    // MARK: - Merge Clusters
    
    private func mergeClusters(
        clusterIndices: [[Int]],
        embeddings: [FaceEmbedding],
        n: Int,
        similarityMatrix: [Float]
    ) -> [[Int]] {
        let m = clusterIndices.count
        guard m > 1 else { return clusterIndices }
        
        let dim = embeddings[0].embedding.count
        
        // 1. centroid 계산
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
        
        // 2. centroid 간 유사도 행렬
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
        
        // 3. 유사도 높은 순 정렬 후 병합
        var pairs: [(i: Int, j: Int, sim: Float)] = []
        for i in 0..<m {
            for j in (i+1)..<m {
                let sim = centroidSim[i * m + j]
                if sim >= mergeThreshold { pairs.append((i, j, sim)) }
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
            let pi = find(pair.i), pj = find(pair.j)
            guard pi != pj else { continue }
            
            var mergedIndices: [Int] = []
            for k in 0..<m {
                if find(k) == pi || find(k) == pj {
                    mergedIndices.append(contentsOf: clusterIndices[k])
                }
            }
            
            // 병합 후 품질 검증
            let cleaned = removeOutliers(indices: mergedIndices, n: n, similarityMatrix: similarityMatrix)
            guard cleaned.count >= minimumClusterSize else { continue }
            
            parent[pi] = pj
            print("🔀 클러스터 병합 (centroid 유사도: \(String(format: "%.4f", pair.sim)))")
        }
        
        // 4. 결과 그룹핑
        var merged: [Int: [Int]] = [:]
        for i in 0..<m {
            merged[find(i), default: []].append(contentsOf: clusterIndices[i])
        }
        
        return Array(merged.values)
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
                if totalSim / denominator >= minimumInternalSimilarity {
                    filtered.append(idxA)
                }
            }
            
            if filtered.count == current.count { break }
            current = filtered
        }
        
        return current
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
