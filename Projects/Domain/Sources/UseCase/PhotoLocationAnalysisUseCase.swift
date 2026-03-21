//
//  PhotoLocationAnalysisUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/21/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public final class PhotoLocationAnalysisUseCase {
    
    private let libraryRepository: PhotoLibraryRepository
    private let analysisRepository: PhotoAnalysisRepository
    
    public init(
        libraryRepository: PhotoLibraryRepository,
        analysisRepository: PhotoAnalysisRepository
    ) {
        self.libraryRepository = libraryRepository
        self.analysisRepository = analysisRepository
    }
 
    public func analyze() async throws -> AsyncThrowingStream<AnalysisProgress, Error> {
        let photos = try await self.libraryRepository.fetchPhotos(page: 0)
        return analysisRepository.locationAnalyze(photoIds: photos.photos.map {$0.localIdentifier})
    }
}
