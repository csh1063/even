//
//  DefaultPhotoLabelDataRepository.swift
//  Data
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import SwiftData

final public class DefaultPhotoLabelDataRepository: PhotoLabelDataRepository {
    
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func fetchAll() throws -> [PhotoLabel] {
        
        let context = ModelContext(container)
        
        let fetchDescriptor = FetchDescriptor<PhotoLabelEntity>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        return try context.fetch(fetchDescriptor).map {$0.toDomain()}
    }
    
    public func fetchUniqueNames() throws -> [String] {
        let context = ModelContext(self.container)
        let descriptor = FetchDescriptor<PhotoLabelEntity>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        var seen = Set<String>()
        return try context.fetch(descriptor)
            .filter { seen.insert($0.name).inserted }
            .map { $0.toDomain().name }
    }
}
