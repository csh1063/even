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
    private let geocoderService: GeocoderService
    private let batchSize: Int
    
    // MARK: - Init
    
    public init(
        analysisService: PhotoAnalysisService,
        libraryService: PhotoLibraryService,
        geocoderService: GeocoderService,
        batchSize: Int = 20
    ) {
        self.analysisService = analysisService
        self.libraryService = libraryService
        self.geocoderService = geocoderService
        self.batchSize = batchSize
    }
    
    // MARK: - Public
    /// 여러 사진 배치 분석 → 진행률 스트림 반환
    public func analyze() -> AsyncThrowingStream<AnalysisProgress, Error> {
        print("DefaultPhotoAnalysisRepository analyze")
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let photos = try await libraryService.getPhotoList(page: 0).photos
                    let total = photos.count
                    var completed = 0
                    let batches = photos.chunked(into: batchSize)
                    
                    for batch in batches {
                        try await withThrowingTaskGroup(of: (PhotoAssetEntity, [PhotoLabel]).self) { group in
                            for photo in batch {
                                group.addTask {
                                    let photoId = photo.asset.localIdentifier
                                    let labels = try await self.analyzeSingle(photoId: photoId)
                                    print("id: ", photoId, "/ labels: ", (labels).map{ $0.name }.joined(separator: ", "))
                                    return (photo, labels)
                                }
                            }
                            
                            for try await (photo, labels) in group {
                                completed += 1
                                let progress = Double(Double(completed)/Double(total))
                                print("completed: \(completed), \(Double(completed))")
                                print("total: \(total), \(Double(total))")
                                print("progress: \(progress), \(Double(completed/total))")
                                continuation.yield(
                                    AnalysisProgress(
                                        photo: Photo(
                                            localIdentifier: photo.asset.localIdentifier,
                                            createdAt: photo.asset.creationDate ?? Date()),
                                        labels: labels,
                                        completed: completed,
                                        total: total,
                                        state: progress == 1 ? .completed:.progress(progress)
                                    )
                                )
                            }
                        }
                        
                        // 배치 사이에 딜레이
//                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1.5초
                    }
                    continuation.finish()
                }
                catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func locationAnalyze() -> AsyncThrowingStream<AnalysisProgress, Error> {
        print("DefaultPhotoAnalysisRepository locationAnalyze")
        return AsyncThrowingStream { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    var completed = 0
                    let photos = try await self.libraryService.getPhotoList(page: 0).photos
                    let photoIds = photos.map { $0.asset.localIdentifier }
                    let assets = try await self.libraryService.getPhoto(ids: photoIds)
                    let total = assets.count
                    
                    for (_, asset) in assets.enumerated(){
                        
                        let localLabels: [PhotoLabel]
                        if let location = asset.location {
                            print("has location", location.coordinate)
                            localLabels = try await self.geocoderService.fetchAddress(from: location, id: asset.localIdentifier)
                            print("localLabels: ", localLabels.map{$0.name}.joined(separator: ", "))
                        } else {
                            localLabels = []
                        }
                        
                        completed += 1
                        let progress = Double(Double(completed)/Double(total))
                        continuation.yield(
                            AnalysisProgress(
                                photo: Photo(
                                    localIdentifier: asset.localIdentifier,
                                    createdAt: asset.creationDate ?? Date()),
                                labels: localLabels,
                                completed: completed,
                                total: total,
                                state: progress == 1 ? .completed:.progress(progress)
                            )
                        )
                        try await Task.sleep(nanoseconds: 1_500_000_000)
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
        return try await self.analysisService.analyze(image: cgImage)
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
