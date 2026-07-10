//
//  DefaultPhotoCategoryRepository.swift
//  Data
//
//  Created by sanghyeon on 4/2/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

public class DefaultPhotoCategoryRepository: PhotoCategoryRepository {

    private let service: PhotoCategoryService

    public init(service: PhotoCategoryService) {
        self.service = service
    }

    public func fetchRuleCategories() async throws -> [String: AlbumRule] {
        try await service.fetchRuleCategories()
    }
}
