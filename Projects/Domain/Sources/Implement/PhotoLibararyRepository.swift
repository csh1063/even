//
//  PhotoLibararyRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoLibararyRepository {
    func fetchPhotos(offset: Int, limit: Int) async throws -> [Photo]
}
