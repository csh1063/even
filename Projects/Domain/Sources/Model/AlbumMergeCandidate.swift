//
//  AlbumMergeCandidate.swift
//  Domain
//
//  Created by sanghyeon on 7/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

/// 합치기 후보 앨범 + 현재 앨범과의 centroid 유사도 — 합치기 시트에서 "닮은 사람" / "기타" 구분에 사용
public struct AlbumMergeCandidate: Identifiable {
    public var id: UUID { album.id }
    public let album: Album
    public let similarity: Float

    public init(album: Album, similarity: Float) {
        self.album = album
        self.similarity = similarity
    }
}
