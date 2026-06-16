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
//                                        labels: [],
                                        state: .progress(index/Double(total))
                                    )
                                )
                                index += 1
                                
                            } else {
                                etcPhotos.append(koreaPhoto)
                            }
                        }
                        
                        // 외국 주소
                        print("etcPhotos before", etcPhotos.count)
                        let unique = Dictionary(grouping: etcPhotos) {
                            if let lat = $0.latitude, let lng = $0.longitude {
                                return "\((lat * 10000).rounded() / 10000),\((lng * 10000).rounded() / 10000)"
                            }
                            return ""
                        }
                        print("etcPhotos after", unique.count)
                        
//                        var totalSec = Double(unique.count) * 1.2
//                        print("totalSec", totalSec)
                        
                        let batchSize = 500
                        let uniqueArray = Array(unique)
                        let batches = stride(from: 0, to: uniqueArray.count, by: batchSize).map {
                            Array(uniqueArray[$0..<min($0 + batchSize, uniqueArray.count)])
                        }

                        var overseasAddress: [String: PhotoLocation] = [:]
                        for (i, batch) in batches.enumerated() {
                            let batchDict = Dictionary(uniqueKeysWithValues: batch)
                            print("etcPhotos batch \(i+1)/\(batches.count) start - \(batch.count)개")
                            let batchResult = try await self.geoRepository.locationOverseas(batchDict)
                            print("etcPhotos batch \(i+1) done - 결과 \(batchResult.count)개")
                            overseasAddress.merge(batchResult) { _, new in new }
                        }

                        print("etcPhotos result:", overseasAddress.count)
//                        let overseasAddress = try await self.geoRepository.locationOverseas(unique)
                        
//                        index = 0
                        for etcPhoto in etcPhotos {
                            if let address = overseasAddress[etcPhoto.localIdentifier] {
                                continuation.yield(
                                    ProgressAnalysis(
                                        photo: Photo(
                                            localIdentifier: etcPhoto.localIdentifier,
                                            createdAt: etcPhoto.createdAt,
                                            latitude: etcPhoto.latitude,
                                            longitude: etcPhoto.longitude,
                                            isoCountryCode: address.isoCountryCode ?? "none",
                                            address: address),
//                                        labels: [],
                                        state: .progress(index/Double(total))
                                    )
                                )
                                index += 1
                            } else {
                                print("etcPhotos 매핑 실패", etcPhoto.localIdentifier)
                            }
                        }
//                        for (_, photos) in unique {
//                            
//                            let avgLat = photos.compactMap { $0.latitude }.reduce(0, +) / Double(photos.count)
//                            let avgLng = photos.compactMap { $0.longitude }.reduce(0, +) / Double(photos.count)
//
//                            guard let address = try await self.analysisRepository.geocoderAnalyze(latitude: avgLat, longitude: avgLng) else {
//                                continue
//                            }
//                            
//                            // 3. 같은 그룹 사진들은 결과 재사용
//                            for photo in photos {
//                                index += 1
//                                continuation.yield(
//                                    ProgressAnalysis(
//                                        photo: Photo(
//                                            localIdentifier: photo.localIdentifier,
//                                            createdAt: photo.createdAt,
//                                            latitude: photo.latitude,
//                                            longitude: photo.longitude,
//                                            isoCountryCode: address.isoCountryCode == "" ? "None":address.isoCountryCode,
//                                            address: address),
////                                        labels: [],
//                                        state: .progress(index / Double(total))
//                                    )
//                                )
//                            }
//                            totalSec -= 1.2
//                            
//                            self.timeLog(sec: totalSec)
//                        }
                        
                        print("fail empty photos:", etcPhotos.map {$0.address == nil}.count)
                        
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
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
                            labels: progress.photo.labels
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
    
    private func timeLog(sec: Double) {
        
        let hour = Int(sec / 3600)
        let min = Int(sec.truncatingRemainder(dividingBy: 3600) / 60)
        let sec = Int(sec.truncatingRemainder(dividingBy: 60))
        
        if hour != 0 {
            print(hour, "시간")
        }
        if min != 0 {
            print(min, "분")
        }
        if sec != 0 {
            print(sec, "초")
        }
    }
}
