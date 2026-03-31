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
}

public final class DefaultPhotoLabelUseCase: PhotoLabelUseCase {
    
    private let repository: PhotoLabelDataRepository
    
    public init(repository: PhotoLabelDataRepository) {
        self.repository = repository
    }
    
    public func fetchAll() async throws -> [PhotoLabel] {
        try repository.fetchAll()
    }
}
