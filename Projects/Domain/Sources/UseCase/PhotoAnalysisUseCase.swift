//
//  PhotoAnalysisUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/17/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoAnalysisUseCase {
    func analysis() -> AsyncThrowingStream<ProgressAnalysis, Error>
    func locationAnalysis() -> AsyncThrowingStream<ProgressAnalysis, Error>
    func deletePhotos() async throws
}

public final class DefaultPhotoAnalysisUseCase: PhotoAnalysisUseCase {
    
    private let libraryRepository: PhotoLibraryRepository
    private let analysisRepository: PhotoAnalysisRepository
    private let dataRepository: PhotoDataRepository
    private let geoRepository: GeoRepository
    
    public init(
        libraryRepository: PhotoLibraryRepository,
        analysisRepository: PhotoAnalysisRepository,
        dataRepository: PhotoDataRepository,
        geoRepository: GeoRepository
    ) {
        self.libraryRepository = libraryRepository
        self.analysisRepository = analysisRepository
        self.dataRepository = dataRepository
        self.geoRepository = geoRepository
    }
    
    // 이미지 분석
    public func analysis() -> AsyncThrowingStream<ProgressAnalysis, Error> {
        execute { [weak self] in
            guard let self else {throw PhotoRepositoryError.photoNotFound}
            let analyzedIds: [String] = try self.dataRepository.fetchAnalyzed()
            return self.analysisRepository.analyze(excludingIds: analyzedIds)
        }
    }
    
    // 위치 분석
    public func locationAnalysis() -> AsyncThrowingStream<ProgressAnalysis, Error> {
        execute { [weak self] in
            AsyncThrowingStream { continuation in
                Task.detached(priority: .userInitiated)  {
                    do {
                        guard let self else { throw PhotoRepositoryError.photoNotFound }
                        
                        let unanalyzedPhotos = try self.dataRepository.fetchLocationUnanalyzed()
                        
                        
                        var koreaPhotos: [Photo] = []
                        var etcPhotos: [Photo] = []
                        for unanalyzedPhoto in unanalyzedPhotos {
                            if let latitude = unanalyzedPhoto.latitude,
                               let longitude = unanalyzedPhoto.longitude {
                                if self.isKorea(latitude: latitude, longitude: longitude) {
                                    koreaPhotos.append(unanalyzedPhoto)
                                } else {
                                    etcPhotos.append(unanalyzedPhoto)
                                }
                            }
                        }
                        
                        let total = koreaPhotos.count + etcPhotos.count
                        print("koreaPhotos", koreaPhotos.count)
                        print("etcPhotos", etcPhotos.count)
                        print("total", total)
                        
                        // 한국 주소
                        let koreaAddress = try await self.geoRepository.locationToaddress(koreaPhotos)
                        
                        var index: Double = 0
                        for koreaPhoto in koreaPhotos {
                            if let address = koreaAddress[koreaPhoto.localIdentifier] {
                                
                                continuation.yield(
                                    ProgressAnalysis(
                                        photo: Photo(
                                            localIdentifier: koreaPhoto.localIdentifier,
                                            createdAt: koreaPhoto.createdAt,
                                            latitude: koreaPhoto.latitude,
                                            longitude: koreaPhoto.longitude,
                                            isoCountryCode: address.isoCountryCode,
                                            address: address),
                                        labels: [],
                                        state: .progress(index/Double(total))
                                    )
                                )
                                index += 1
                                
                            } else {
                                etcPhotos.append(koreaPhoto)
                            }
                        }
                        
                        // 외국 주소
                        for etcPhoto in etcPhotos {
                            if let address = try await self.analysisRepository.geocoderAnalyze(etcPhoto) {
                                
                                continuation.yield(
                                    ProgressAnalysis(
                                        photo: Photo(
                                            localIdentifier: etcPhoto.localIdentifier,
                                            createdAt: etcPhoto.createdAt,
                                            latitude: etcPhoto.latitude,
                                            longitude: etcPhoto.longitude,
                                            isoCountryCode: address.isoCountryCode,
                                            address: address),
                                        labels: [],
                                        state: .progress(index/Double(total))
                                    )
                                )
                                index += 1
                            }
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
    
    public func deletePhotos() async throws {
        try self.dataRepository.deleteAll()
    }
    
    // MARK: - Private
    private func execute(
        stream: @escaping () async throws  -> AsyncThrowingStream<ProgressAnalysis, Error>?
    ) -> AsyncThrowingStream<ProgressAnalysis, Error> {
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
    
    private func isKorea(latitude: Double, longitude: Double) -> Bool {
        // 한국 바운딩 박스로 1차 필터 — 폴리곤 순회보다 훨씬 빠름
        return (32.0...39.5).contains(latitude) &&
               (123.5...132.5).contains(longitude)
    }
}
