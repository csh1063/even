//
//  ClusterableEmbedding.swift
//  Domain
//
//  Created by sanghyeon on 7/19/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

/// Data 레이어의 ClusteringEngine이 대상 종류(사람 얼굴/동물 등)를 몰라도 클러스터링할 수 있도록 하는 최소 인터페이스.
/// L2 정규화된 임베딩과, "같은 사진 속 서로 다른 개체는 무조건 다른 개체"를 판단하기 위한 photoId만 있으면 된다.
public protocol ClusterableEmbedding {
    var embedding: [Float] { get }
    var photoId: String { get }
}
