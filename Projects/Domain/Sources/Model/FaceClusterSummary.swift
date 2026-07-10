//
//  FaceClusterSummary.swift
//  Domain
//
//  Created by sanghyeon on 7/10/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

/// 얼굴 앨범 분리 화면에서, 앨범을 구성하는 클러스터 하나를 보여주기 위한 요약 정보
public struct FaceClusterSummary: Identifiable, Equatable {
    public let id: UUID
    public let photoCount: Int
    public let coverPhotoId: String?

    public init(id: UUID, photoCount: Int, coverPhotoId: String?) {
        self.id = id
        self.photoCount = photoCount
        self.coverPhotoId = coverPhotoId
    }
}
