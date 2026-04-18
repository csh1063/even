//
//  GeoRepository.swift
//  Domain
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol GeoRepository {
    func locationToaddress(_ photos: [Photo]) async throws -> [String: PhotoLocation]
}
