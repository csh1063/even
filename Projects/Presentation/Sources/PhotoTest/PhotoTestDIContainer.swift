//
//  PhotoTestDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 4/8/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class PhotoTestDIContainer {

    private let photoDataRepository: PhotoDataRepository
    private let geoRepository: GeoRepository
    
    public init(photoDataRepository: PhotoDataRepository,
                geoRepository: GeoRepository) {
        self.photoDataRepository = photoDataRepository
        self.geoRepository = geoRepository
    }

    func makePhotoTestViewModel(pop: @escaping () -> Void) -> PhotoTestViewModel {
        
        let useCase = DefaultPhotoTestUseCase(
            repository: photoDataRepository,
            geoRepository: geoRepository
        )
        
        return PhotoTestViewModel(useCase: useCase, pop: pop)
    }
}
