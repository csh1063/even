//
//  DefaultHomeZoneRepository.swift
//  Data
//
//  Created by sanghyeon on 5/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Domain
import SwiftData
import Foundation

public final class DefaultHomeZoneRepository: HomeZoneRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchHomeZones() throws -> [HomeZone] {
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<HomeZoneEntity>()
        return try context.fetch(descriptor).map {
            HomeZone(latitude: $0.latitude, longitude: $0.longitude, analyzedAt: $0.analyzedAt)
        }
    }

    public func saveHomeZones(_ zones: [HomeZone]) throws {
        let context = ModelContext(container)
        try deleteAllHomeZones()
        for zone in zones {
            let entity = HomeZoneEntity(latitude: zone.latitude, longitude: zone.longitude, analyzedAt: zone.analyzedAt)
            context.insert(entity)
        }
        try context.save()
    }

    public func deleteAllHomeZones() throws {
        let context = ModelContext(container)
        try context.delete(model: HomeZoneEntity.self)
    }
}
