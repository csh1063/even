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

    private let photoLabelDataRepository: PhotoLabelDataRepository
    
    public init(photoLabelDataRepository: PhotoLabelDataRepository) {
        self.photoLabelDataRepository = photoLabelDataRepository
    }
    
    func makeLabelsViewModel(pop: @escaping () -> Void) -> LabelsViewModel {
        
        let useCase = DefaultPhotoLabelUseCase(
            repository: photoLabelDataRepository
        )
        
        return LabelsViewModel(useCase: useCase, pop: pop)
    }
}
