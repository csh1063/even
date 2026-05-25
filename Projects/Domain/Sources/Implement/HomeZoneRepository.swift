//
//  HomeZoneRepository.swift
//  Domain
//
//  Created by sanghyeon on 5/24/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


public protocol HomeZoneRepository {
    func fetchHomeZones() throws -> [HomeZone]
    func saveHomeZones(_ zones: [HomeZone]) throws
    func deleteAllHomeZones() throws
}