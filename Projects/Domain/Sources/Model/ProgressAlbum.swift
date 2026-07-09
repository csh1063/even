//
//  ProgressAlbum.swift
//  Domain
//
//  Created by sanghyeon on 3/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public struct ProgressAlbum {
    public let step: AlbumStep
    public let ratio: Double

    public enum AlbumStep {
        case analyzing      // 라벨 집계 중
        case creatingAlbums // 앨범 생성 중
        case classifying    // 사진 분류 중
        case completed
    }
}
