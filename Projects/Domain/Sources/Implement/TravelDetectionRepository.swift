//
//  TravelDetectionRepository.swift
//  Domain
//
//  Created by sanghyeon on 5/6/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//



public protocol TravelDetectionRepository {
    func detect(from photos: [PhotoLocationSnapshot]) -> [TravelCluster]
}
