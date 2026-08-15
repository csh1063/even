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
    func markAnalysisStarted() async throws
    func markAnalysisFinished() async throws
    func isAnalysisInterrupted() async throws -> Bool
}

public final class DefaultPhotoAnalysisUseCase: PhotoAnalysisUseCase {

    private let libraryRepository: PhotoLibraryRepository
    private let analysisRepository: PhotoAnalysisRepository
    private let dataRepository: PhotoDataRepository
    private let geoRepository: GeoRepository
    private let userDefaultRepository: UserDefaultRepository

    // 라벨+얼굴 분석과 주소 변환을 동시에 진행할 때의 진행률 가중치
    private let labelWeight: Double = 4.0 / 5.0
    private let addressWeight: Double = 1.0 / 5.0

    public init(
        libraryRepository: PhotoLibraryRepository,
        analysisRepository: PhotoAnalysisRepository,
        dataRepository: PhotoDataRepository,
        geoRepository: GeoRepository,
        userDefaultRepository: UserDefaultRepository
    ) {
        self.libraryRepository = libraryRepository
        self.analysisRepository = analysisRepository
        self.dataRepository = dataRepository
        self.geoRepository = geoRepository
        self.userDefaultRepository = userDefaultRepository
    }

    public func markAnalysisStarted() async throws {
        try await userDefaultRepository.saveAnalysisInProgress(true)
    }

    public func markAnalysisFinished() async throws {
        try await userDefaultRepository.saveAnalysisInProgress(false)
    }

    public func isAnalysisInterrupted() async throws -> Bool {
        try await userDefaultRepository.fetchAnalysisInProgress()
    }

    // 사진 기본 정보 저장 → 라벨+얼굴 분석과 주소 변환 동시 진행 (4:1 가중 진행률)
    public func analysis() -> AsyncThrowingStream<ProgressAnalysis, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await saveAllPhotosBase()

                    let combiner = ProgressCombiner(labelWeight: labelWeight, addressWeight: addressWeight)

                    try await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask { [weak self] in
                            guard let self else { return }
                            for try await progress in self.labelAndFaceStream() {
                                switch progress.state {
                                case .progress(let ratio):
                                    let combined = await combiner.updateLabel(ratio)
                                    continuation.yield(ProgressAnalysis(photo: progress.photo, state: .progress(combined)))
                                case .completed:
                                    let combined = await combiner.updateLabel(1.0)
                                    continuation.yield(ProgressAnalysis(photo: progress.photo, state: .progress(combined)))
                                case .unavailable(let reason):
                                    continuation.yield(ProgressAnalysis(photo: progress.photo, state: .unavailable(reason: reason)))
                                }
                            }
                        }
                        group.addTask { [weak self] in
                            guard let self else { return }
                            // 주소(네트워크) 분석이 실패해도 라벨/얼굴 분석과 앨범 생성은 계속 진행돼야 한다 —
                            // 여기서 던지면 group.waitForAll()이 통째로 실패해서 아래 앨범 생성 자체가 안 불린다
                            do {
                                for try await progress in self.addressStream() {
                                    switch progress.state {
                                    case .progress(let ratio):
                                        let combined = await combiner.updateAddress(ratio)
                                        continuation.yield(ProgressAnalysis(photo: progress.photo, state: .progress(combined)))
                                    case .completed:
                                        let combined = await combiner.updateAddress(1.0)
                                        continuation.yield(ProgressAnalysis(photo: progress.photo, state: .progress(combined)))
                                    case .unavailable(let reason):
                                        continuation.yield(ProgressAnalysis(photo: progress.photo, state: .unavailable(reason: reason)))
                                    }
                                }
                            } catch {
                                debugLog("⚠️ 주소 분석 실패, 무시하고 계속 진행: \(error)")
                                _ = await combiner.updateAddress(1.0)
                            }
                        }
                        try await group.waitForAll()
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    // 주소 변환만 단독으로 (외부 단독 트리거용으로 프로토콜에 유지)
    public func locationAnalysis() -> AsyncThrowingStream<ProgressAnalysis, Error> {
        addressStream()
    }

    // MARK: - Private

    /// 라이브러리 전체 사진의 기본 메타데이터(id/createdAt/lat/lng/year/month)를 분석 전에 미리 저장
    private func saveAllPhotosBase() async throws {
        let allPhotos = try await libraryRepository.fetchPhotos()
        let photos = allPhotos.photos.map { item -> Photo in
            let createdAt = item.createdDate ?? Date()
            let components = Calendar.current.dateComponents([.year, .month], from: createdAt)
            return Photo(
                localIdentifier: item.localIdentifier,
                createdAt: createdAt,
                latitude: item.latitude,
                longitude: item.longitude,
                year: components.year.map { String($0) },
                month: components.month.map { String($0) }
            )
        }
        try dataRepository.saveAllPhotosBase(photos)
    }

    // 라벨 + 얼굴 임베딩 분석
    private func labelAndFaceStream() -> AsyncThrowingStream<ProgressAnalysis, Error> {
        execute { [weak self] in
            guard let self else { throw PhotoRepositoryError.photoNotFound }
            let analyzedIds: [String] = try self.dataRepository.fetchAnalyzed()
            return self.analysisRepository.analyze(excludingIds: analyzedIds)
        }
    }

    // 주소 변환
    private func addressStream() -> AsyncThrowingStream<ProgressAnalysis, Error> {
        execute { [weak self] in
            AsyncThrowingStream { continuation in
                let task = Task.detached(priority: .userInitiated) {
                    do {
                        guard let self else { throw PhotoRepositoryError.photoNotFound }

                        let unanalyzedPhotos = try self.dataRepository.fetchLocationUnanalyzed()

                        var koreaPhotos: [Photo] = []
                        var etcPhotos: [Photo] = []
                        var noCodePhotos: [Photo] = []
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

                        // 한국 주소 — 실패해도 외국 주소 조회는 이어서 시도해야 한다
                        let koreaAddress: [String: PhotoLocation]
                        do {
                            koreaAddress = try await self.geoRepository.locationToaddress(koreaPhotos)
                        } catch {
                            debugLog("⚠️ 한국 주소 조회 실패, 무시하고 계속 진행: \(error)")
                            koreaAddress = [:]
                        }

                        var index: Double = 0
                        for koreaPhoto in koreaPhotos {
                            if let address = koreaAddress[koreaPhoto.localIdentifier] {

                                index += 1
                                continuation.yield(
                                    ProgressAnalysis(
                                        photo: Photo(
                                            localIdentifier: koreaPhoto.localIdentifier,
                                            createdAt: koreaPhoto.createdAt,
                                            latitude: koreaPhoto.latitude,
                                            longitude: koreaPhoto.longitude,
                                            isoCountryCode: address.isoCountryCode,
                                            address: address),
                                        state: .progress(index/Double(total))
                                    )
                                )

                            } else {
                                etcPhotos.append(koreaPhoto)
                            }
                        }

                        // 외국 주소
                        let unique = Dictionary(grouping: etcPhotos) {
                            if let lat = $0.latitude, let lng = $0.longitude {
                                return "\((lat * 10000).rounded() / 10000),\((lng * 10000).rounded() / 10000)"
                            }
                            return ""
                        }

                        let batchSize = 50
                        let uniqueArray = Array(unique)
                        let batches = stride(from: 0, to: uniqueArray.count, by: batchSize).map {
                            Array(uniqueArray[$0..<min($0 + batchSize, uniqueArray.count)])
                        }

                        var overseasAddress: [String: PhotoLocation] = [:]
                        for batch in batches {
                            let batchDict = Dictionary(uniqueKeysWithValues: batch)
                            do {
                                let batchResult = try await self.geoRepository.locationOverseas(batchDict)
                                overseasAddress.merge(batchResult) { _, new in new }
                            } catch {
                                debugLog("⚠️ 해외 주소 배치 조회 실패, 이 배치만 건너뜀: \(error)")
                            }
                        }

                        for etcPhoto in etcPhotos {
                            if let address = overseasAddress[etcPhoto.localIdentifier],
                               let isoCountryCode = address.isoCountryCode,
                               address.isoCountryCode != "none" {

                                index += 1
                                continuation.yield(
                                    ProgressAnalysis(
                                        photo: Photo(
                                            localIdentifier: etcPhoto.localIdentifier,
                                            createdAt: etcPhoto.createdAt,
                                            latitude: etcPhoto.latitude,
                                            longitude: etcPhoto.longitude,
                                            isoCountryCode: isoCountryCode,
                                            address: address),
                                        state: .progress(index/Double(total))
                                    )
                                )
                            } else {
                                noCodePhotos.append(etcPhoto)
                            }
                        }

                        for photo in noCodePhotos {
                            try Task.checkCancellation()

                            guard let latitude = photo.latitude, let longitude = photo.longitude else {
                                continue
                            }

                            let address: PhotoLocation
                            do {
                                guard let resolved = try await self.analysisRepository.geocoderAnalyze(
                                    latitude: latitude, longitude: longitude) else {
                                    continue
                                }
                                address = resolved
                            } catch {
                                debugLog("⚠️ 개별 사진 주소 조회 실패, 이 사진만 건너뜀: \(error)")
                                continue
                            }

                            index += 1
                            continuation.yield(
                                ProgressAnalysis(
                                    photo: Photo(
                                        localIdentifier: photo.localIdentifier,
                                        createdAt: photo.createdAt,
                                        latitude: photo.latitude,
                                        longitude: photo.longitude,
                                        isoCountryCode: address.isoCountryCode == "" ? "NO":address.isoCountryCode ?? "NO",
                                        address: address),
                                    state: .progress(index / Double(total))
                                )
                            )
                        }

                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { @Sendable _ in task.cancel() }
            }
        }
    }

    private func execute(
        stream: @escaping () async throws -> AsyncThrowingStream<ProgressAnalysis, Error>?
    ) -> AsyncThrowingStream<ProgressAnalysis, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
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
            continuation.onTermination = { @Sendable _ in task.cancel() }
        }
    }

    private func isKorea(latitude: Double, longitude: Double) -> Bool {
        // 한국 바운딩 박스로 1차 필터 — 폴리곤 순회보다 훨씬 빠름
        return (32.0...39.5).contains(latitude) &&
               (123.5...132.5).contains(longitude)
    }
}

/// 라벨+얼굴 분석과 주소 변환이 동시에 진행될 때 각각의 최신 진행률을 가중합해서 하나의 진행률로 합친다.
private actor ProgressCombiner {
    private let labelWeight: Double
    private let addressWeight: Double

    private var labelRatio: Double = 0
    private var addressRatio: Double = 0

    init(labelWeight: Double, addressWeight: Double) {
        self.labelWeight = labelWeight
        self.addressWeight = addressWeight
    }

    private var combined: Double {
        labelRatio * labelWeight + addressRatio * addressWeight
    }

    func updateLabel(_ ratio: Double) -> Double {
        labelRatio = ratio
        return combined
    }

    func updateAddress(_ ratio: Double) -> Double {
        addressRatio = ratio
        return combined
    }
}
