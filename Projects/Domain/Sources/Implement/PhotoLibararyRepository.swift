//
//  PhotoLibraryRepository.swift
//  Domain
//
//  Created by sanghyeon on 3/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PhotoLibraryRepository {
    func fetchPhotos(page: Int) async throws -> PhotoList
    func checkPermission() async throws -> PhotoPermission
    func loadImage<T>(id: String, type: LoadPhotoOptionType) async throws -> ImageData<T>
}
