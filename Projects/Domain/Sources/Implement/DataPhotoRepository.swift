//
//  DataPhotoRepository.swift
//  Domain
//
//  Created by sanghyeon on 2/26/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol DataPhotoRepository {
    func fetchAll() async throws -> [Photo]
    func fetch(page: Int, pageSize: Int) async throws -> [Photo]
    func create(_ photo: Photo) async throws
    func update(_ photo: Photo) async throws
    func delete(_ photo: Photo) async throws
}
