//
//  LabelsDIContainer.swift
//  Presentation
//
//  Created by sanghyeon on 3/31/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

@MainActor
public final class LabelsDIContainer {

    private let photoDataRepository: PhotoDataRepository
    private let photoLabelDataRepository: PhotoLabelDataRepository
    private let isLabel: Bool
    
    public init(isLabel: Bool,
                photoDataRepository: PhotoDataRepository,
                photoLabelDataRepository: PhotoLabelDataRepository) {
        self.isLabel = isLabel
        self.photoDataRepository = photoDataRepository
        self.photoLabelDataRepository = photoLabelDataRepository
    }
    
    func makeLabelsViewModel(pop: @escaping () -> Void) -> LabelsViewModel {
        
        let useCase = DefaultPhotoLabelUseCase(
            photoRepository: photoDataRepository,
            labelRepository: photoLabelDataRepository
        )
        
        return LabelsViewModel(isLabel: isLabel, useCase: useCase, pop: pop)
    }
}
