//
//  PhotoCategoryRepository.swift
//  Domain
//
//  Created by sanghyeon on 4/2/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoCategoryRepository {
    func fetchCategories() async throws -> [String: [String]]
}
