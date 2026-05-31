//
//  FaceClusterRepository.swift
//  Domain
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation

public protocol FaceClusterRepository {
    func clusterAndSaveAlbums() async throws
}
