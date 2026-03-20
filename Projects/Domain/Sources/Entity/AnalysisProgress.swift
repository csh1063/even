//
//  AnalysisProgress.swift
//  Domain
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


public struct AnalysisProgress {
    public let identifier: String
    public let labels: [PhotoLabel]
    public let completed: Int
    public let total: Int
    public let state: AnalysisState
    
    public var ratio: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    public init(identifier: String, labels: [PhotoLabel], completed: Int, total: Int, state: AnalysisState) {
        self.identifier = identifier
        self.labels = labels
        self.completed = completed
        self.total = total
        self.state = state
    }
}
