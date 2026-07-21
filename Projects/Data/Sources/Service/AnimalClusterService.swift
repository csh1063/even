//
//  AnimalClusterService.swift
//  Data
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//
//  FaceClusterService와 동일하게, 실제 클러스터링 알고리즘은 ClusteringEngine에 있고
//  여기는 그걸 동물(DINOv2, 384차원) 기준값으로 감싸는 얇은 래퍼다.

import Domain
import Foundation

public final class AnimalClusterService {

    private let engine = ClusteringEngine<AnimalEmbedding>(config: .animalDefault, logTag: "AnimalClusterService")

    public init() { }

    public func cluster(embeddings: [AnimalEmbedding]) -> [ClusterResult<AnimalEmbedding>] {
        engine.cluster(embeddings: embeddings)
    }

    public func clusterWithLeftoverRetry(embeddings: [AnimalEmbedding]) -> ClusteringOutcome<AnimalEmbedding> {
        engine.clusterWithLeftoverRetry(embeddings: embeddings, maxRetryRounds: 3)
    }
}
