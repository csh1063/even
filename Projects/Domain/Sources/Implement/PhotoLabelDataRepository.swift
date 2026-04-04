//
//  PhotoLabelDataRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoLabelDataRepository {
    func fetchAll() throws -> [PhotoLabel]
    func fetchUniqueNames() throws -> [String]
}
