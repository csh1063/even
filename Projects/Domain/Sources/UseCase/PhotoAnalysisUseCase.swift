//
//  PhotoAnalysisUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoAnalysisUseCase {
    func analysis(isFull: Bool) -> AsyncThrowingStream<AnalysisProgress, Error>
    func locationAnalysis(isFull: Bool) -> AsyncThrowingStream<AnalysisProgress, Error>
    func deletePhotos() async throws
}

public final class DefaultPhotoAnalysisUseCase: PhotoAnalysisUseCase {
    
    private let libraryRepository: PhotoLibraryRepository
    private let analysisRepository: PhotoAnalysisRepository
    private let dataRepository: PhotoDataRepository
    
    public init(
        libraryRepository: PhotoLibraryRepository,
        analysisRepository: PhotoAnalysisRepository,
        dataRepository: PhotoDataRepository
    ) {
        self.libraryRepository = libraryRepository
        self.analysisRepository = analysisRepository
        self.dataRepository = dataRepository
    }
    
    // 이미지 분석
    public func analysis(isFull: Bool) -> AsyncThrowingStream<AnalysisProgress, Error> {
        execute { [weak self] in
            
            let analyzedIds: [String]?
            if isFull {
                analyzedIds = nil
            } else {
                analyzedIds = try self?.dataRepository.fetchAll()
                    .filter { $0.analyzedAt != nil }
                    .map { $0.localIdentifier }
            }
            
            return self?.analysisRepository.analyze(excludingIds: analyzedIds)
        }
    }
    
    // 위치 분석
    public func locationAnalysis(isFull: Bool) -> AsyncThrowingStream<AnalysisProgress, Error> {
        execute { [weak self] in
            
            let analyzedIds: [String]?
            if isFull {
                analyzedIds = nil
            } else {
                analyzedIds = try self?.dataRepository.fetchAll()
                    .filter { $0.address != nil }
                    .map { $0.localIdentifier }
            }
            
            return self?.analysisRepository.locationAnalyze(excludingIds: analyzedIds)
        }
    }
    
    public func deletePhotos() async throws {
        try self.dataRepository.deleteAll()
    }
    
    // MARK: - Private
    private func execute(
        stream: @escaping () async throws  -> AsyncThrowingStream<AnalysisProgress, Error>?
    ) -> AsyncThrowingStream<AnalysisProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let analysisStream = try await stream() else {
                        continuation.finish()
                        return
                    }
                    
                    for try await progress in analysisStream {
                        try await dataRepository.saveAndUpdateLabels(
                            photo: progress.photo,
                            labels: progress.labels
                        )
                        continuation.yield(progress)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
