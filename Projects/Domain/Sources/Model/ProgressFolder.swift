//
//  ProgressFolder.swift
//  Domain
//
//  Created by sanghyeon on 3/22/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


public struct ProgressFolder {
    public let step: FolderStep
    public let ratio: Double
    
    public enum FolderStep {
        case analyzing      // 라벨 집계 중
        case creatingFolders // 폴더 생성 중
        case classifying    // 사진 분류 중
        case completed
    }
}
