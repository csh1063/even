//
//  PhotoLabelUseCase.swift
//  Domain
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoLabelUseCase {
    func fetchAll() async throws -> [PhotoLabel]
    func fetchUniqueNames() async throws -> [String]
    func fetchLabelCounts() async throws -> [(name: String, count: Int)]
    func fetchAddressCounts() async throws -> [(name: String, count: Int)]
}

public final class DefaultPhotoLabelUseCase: PhotoLabelUseCase {

    private let photoRepository: PhotoDataRepository
    private let labelRepository: PhotoLabelDataRepository

    public init(
        photoRepository: PhotoDataRepository,
        labelRepository: PhotoLabelDataRepository
    ) {
        self.photoRepository = photoRepository
        self.labelRepository = labelRepository
    }

    public func fetchAll() async throws -> [PhotoLabel] {
        try labelRepository.fetchAll()
    }

    public func fetchUniqueNames() async throws -> [String] {
        try labelRepository.fetchUniqueNames()
    }

    public func fetchLabelCounts() async throws -> [(name: String, count: Int)] {
        try labelRepository.fetchLabelCounts()
    }

    public func fetchAddressCounts() async throws -> [(name: String, count: Int)] {
        let photo = try photoRepository.fetchPhotos()

        let map = Dictionary(grouping: photo) {
            if let address = $0.address,
               let country = address.country,
               let administrativeArea = address.administrativeArea,
               let locality = address.locality {
                return "\(country) \(administrativeArea) \(locality)"
            } else {
                return "no address"
            }
        }
            .map {
                (name: $0.key, count: $0.value.count)
            }
            .sorted {
                $0.name < $1.name
            }

        return map
    }
}
