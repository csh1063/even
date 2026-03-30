//
//  PhotoAnalysisRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoAnalysisRepository {
    func analyze(excludingIds: [String]?) -> AsyncThrowingStream<AnalysisProgress, Error>
    func locationAnalyze(excludingIds: [String]?) -> AsyncThrowingStream<AnalysisProgress, Error>
    func analyzeSingle(photoId: String) async throws  -> [PhotoLabel]
}
