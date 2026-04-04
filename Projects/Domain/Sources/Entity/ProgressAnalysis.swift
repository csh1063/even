//
//  ProgressAnalysis.swift
//  Domain
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

public struct ProgressAnalysis {
    public let photo: Photo
    public let labels: [PhotoLabel]
    public let state: ProgressState
    
    public init(photo: Photo, labels: [PhotoLabel], state: ProgressState) {
        self.photo = photo
        self.labels = labels
        self.state = state
    }
}
