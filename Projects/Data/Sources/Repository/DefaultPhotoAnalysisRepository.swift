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
    public func analyze(excludingIds: [String]? = nil) -> AsyncThrowingStream<ProgressAnalysis, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let photos: [PhotoAssetEntity]

                    if let excludingIds {
                        let allAssets = try await libraryService.getPhotoList(page: 0).photos
                        photos = allAssets.filter { !excludingIds.contains($0.asset.localIdentifier) }
                    } else {
                        photos = try await libraryService.getPhotoList(page: 0).photos
                    }
                    
                    let total = photos.count
                    var completed = 0
                    let batches = photos.chunked(into: batchSize)
                    
                    for batch in batches {
                        try await withThrowingTaskGroup(of: (PhotoAssetEntity, [PhotoLabel]).self) { group in
                            for photo in batch {
                                group.addTask {
                                    let photoId = photo.asset.localIdentifier
                                    let labels = try await self.analyzeSingle(photoId: photoId)
                                    return (photo, labels)
                                }
                            }
                            
                            for try await (photo, labels) in group {
                                completed += 1
                                let progress = Double(Double(completed)/Double(total))
                                let (year, month): (String?, String?) = {
                                    guard let date = photo.asset.creationDate else { return (nil, nil) }
                                    let components = Calendar.current.dateComponents([.year, .month], from: date)
                                    return (components.year.map { String($0) }, components.month.map { String($0) })
                                }()
                                
                                print("id: ", photo.asset.localIdentifier, "/ year: ", year ?? "?", ", month:",month ?? "?")
                                print("labels: ", (labels).map{ $0.name }.joined(separator: ", "))
                                continuation.yield(
                                    ProgressAnalysis(
                                        photo: Photo(
                                            localIdentifier: photo.asset.localIdentifier,
                                            createdAt: photo.asset.creationDate ?? Date(),
                                            year: year,
                                            month: month
                                        ),
                                        labels: labels,
                                        state: progress == 1 ? .completed:.progress(progress)
                                    )
                                )
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func locationAnalyze(excludingIds: [String]? = nil) -> AsyncThrowingStream<ProgressAnalysis, Error> {
        
        return AsyncThrowingStream { continuation in
            Task.detached(priority: .userInitiated) {
                do {
                    var completed = 0
                    let photos = try await self.libraryService.getPhotoList(page: 0).photos
                    let photoIds: [String]

                    if let excludingIds {
                        let allIds = photos.map { $0.asset.localIdentifier }
                        photoIds = allIds.filter { !excludingIds.contains($0) }
                    } else {
                        photoIds = photos.map { $0.asset.localIdentifier }
                    }
                    
                    let assets = try await self.libraryService.getPhoto(ids: photoIds)
                    let total = assets.count
                    
                    for (_, asset) in assets.enumerated() {

                        let latitude: Double?
                        let longitude: Double?
                        let address: PhotoLocation?
                        let addressEn: PhotoLocation?

                        if let location = asset.location {
                            latitude = location.coordinate.latitude
                            longitude = location.coordinate.longitude
                            
                            address = try await self.geocoderService.fetchAddress(
                                from: location,
                                id: asset.localIdentifier,
                                locale: Locale(identifier: "ko"))
                            print(
                                "id: ", asset.localIdentifier,
                                "location:", "\(address?.country ?? ""), \(address?.locality ?? "")")
//                            addressEn = try await self.geocoderService.fetchAddress(
//                                from: location,
//                                id: asset.localIdentifier,
//                                locale: Locale(identifier: "en"))
                        } else {
                            latitude = nil
                            longitude = nil
                            address = nil
//                            addressEn = nil
                        }
                        addressEn = nil
                        
                        completed += 1
                        let progress = Double(Double(completed)/Double(total))
                        continuation.yield(
                            ProgressAnalysis(
                                photo: Photo(
                                    localIdentifier: asset.localIdentifier,
                                    createdAt: asset.creationDate ?? Date(),
                                    latitude: latitude,
                                    longitude: longitude,
                                    isoCountryCode: address?.isoCountryCode,
                                    address: address,
                                    addressEn: addressEn),
                                labels: [],
                                state: progress == 1 ? .completed:.progress(progress)
                            )
                        )
                        try await Task.sleep(nanoseconds: 1_500_000_000)
                    }
                    
                    continuation.finish()
                } catch {
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
