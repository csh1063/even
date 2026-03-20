//
//  PhotoAnalysisUsecase.swift
//  Domain
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public final class PhotoAnalysisUsecase {
    
    private let libraryRepository: PhotoLibraryRepository
    private let analysisRepository: PhotoAnalysisRepository
    
    public init(
        libraryRepository: PhotoLibraryRepository,
        analysisRepository: PhotoAnalysisRepository
    ) {
        self.libraryRepository = libraryRepository
        self.analysisRepository = analysisRepository
    }
 
    public func analysis() async throws -> AsyncThrowingStream<AnalysisProgress, Error> {
        let photos = try await self.libraryRepository.fetchPhotos(page: 0)
        return analysisRepository.analyze(photoIds: photos.photos.map {$0.localIdentifier})
    }
}
