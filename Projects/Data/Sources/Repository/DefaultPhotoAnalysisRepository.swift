//
//  DefaultPhotoAnalysisRepository.swift
//  Data
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import CoreGraphics

// Data 모듈
public final class DefaultPhotoAnalysisRepository: PhotoAnalysisRepository {
    
    // MARK: - Properties
    
    private let analysisService: PhotoAnalysisService
    private let libraryService: PhotoLibraryService  // 이미지 로드용
    private let batchSize: Int
    
    // MARK: - Init
    
    public init(
        analysisService: PhotoAnalysisService,
        libraryService: PhotoLibraryService,
        batchSize: Int = 20
    ) {
        self.analysisService = analysisService
        self.libraryService = libraryService
        self.batchSize = batchSize
    }
    
    // MARK: - Public
    
    /// 여러 사진 배치 분석 → 진행률 스트림 반환
    public func analyze(photoIds: [String]) -> AsyncThrowingStream<AnalysisProgress, Error> {
        print("DefaultPhotoAnalysisRepository analyze")
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let total = photoIds.count
                    var completed = 0
                    let batches = photoIds.chunked(into: batchSize)
                    
                    for batch in batches {
                        try await withThrowingTaskGroup(of: (String, [PhotoLabel]).self) { group in
                            for photoId in batch {
                                group.addTask {
                                    let labels = try await self.analyzeSingle(photoId: photoId)
                                    print("id: ", photoId, "/ labels: ", labels.map{ $0.name }.joined(separator: ", "))
                                    return (photoId, labels)
                                }
                            }
                            
                            for try await (identifier, labels) in group {
                                completed += 1
                                let progress = Double(completed/total)
                                let state: AnalysisState
//                                if labels == [] {
//                                    state = .unavailable(reason: "fail model loading")
//                                } else {
                                    state = progress == 1 ? .completed:.progress(progress)
//                                }
                                
                                continuation.yield(
                                    AnalysisProgress(
                                        identifier: identifier,
                                        labels: labels,
                                        completed: completed,
                                        total: total,
                                        state: state
                                    )
                                )
                            }
                        }
                    }
                    continuation.finish()
                }
                catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// 단일 사진 분석
    public func analyzeSingle(photoId: String) async throws -> [PhotoLabel] {
        guard let cgImage = try? await loadImage(photoId: photoId) else {
            return []
        }
        return try await analysisService.analyze(image: cgImage)
    }
    
    // MARK: - Private
    private func loadImage(photoId: String) async throws -> CGImage? {
        try await libraryService.loadImage(
            id: photoId,
            type: .specialSize(CGSize(width: 224, height: 224))
        )
    }
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
