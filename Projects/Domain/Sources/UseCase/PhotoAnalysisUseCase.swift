//
//  PhotoAnalysisUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoAnalysisUseCase {
    func analysis() -> AsyncThrowingStream<AnalysisProgress, Error>
    func locationAnalysis() -> AsyncThrowingStream<AnalysisProgress, Error>
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
    public func analysis() -> AsyncThrowingStream<AnalysisProgress, Error> {
        execute { [weak self] in
            self?.analysisRepository.analyze()
        }
    }
    
    // 위치 분석
    public func locationAnalysis() -> AsyncThrowingStream<AnalysisProgress, Error> {
        execute { [weak self] in
            self?.analysisRepository.locationAnalyze()
        }
    }
    
    public func deletePhotos() async throws {
        try self.dataRepository.deleteAll()
    }
    
    // MARK: - Private
    private func execute(
        _ stream: @escaping () -> AsyncThrowingStream<AnalysisProgress, Error>?
    ) -> AsyncThrowingStream<AnalysisProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let analysisStream = stream() else {
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
