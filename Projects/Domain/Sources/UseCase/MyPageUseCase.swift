//
//  MyPageUseCase.swift
//  Domain
//
//  Created by sanghyeon on 4/30/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol MyPageUseCase {
    func photoCount() async throws -> Int
    func lastAnalyzeDate() async throws -> String
    func photoUnanalysisCount() async throws -> Int
    func checkPermission() async throws -> PhotoPermission
    func getDisplayMode() async throws -> String
    func changeDisplayMode(_ mode: String) async throws
    func nextDisplayMode() async throws -> String
}

public final class DefaultMyPageUseCase: MyPageUseCase {
    
    private let photoLibraryRepository: PhotoLibraryRepository
    private let photoDataRepository: PhotoDataRepository
    private let userDefaultRepository: UserDefaultRepository
    
    public init(photoLibraryRepository: PhotoLibraryRepository,
                photoDataRepository: PhotoDataRepository,
                userDefaultRepository: UserDefaultRepository) {
        self.photoLibraryRepository = photoLibraryRepository
        self.photoDataRepository = photoDataRepository
        self.userDefaultRepository = userDefaultRepository
    }
    
    public func photoCount() async throws -> Int {
        try photoDataRepository.fetchPhotoCount()
    }
    
    public func lastAnalyzeDate() async throws -> String {
        try await userDefaultRepository.fetchAnalyzedDate()
    }
    
    public func photoUnanalysisCount() async throws -> Int {
        let photoIds = try await self.photoLibraryRepository.fetchPhotoIds()
        let analyzedIds = Set(try photoDataRepository.fetchAnalyzed())
        return photoIds.filter { !analyzedIds.contains($0) }.count
    }
    
    public func checkPermission() async throws -> PhotoPermission {
        try await photoLibraryRepository.checkPermission()
    }
    
    public func getDisplayMode() async throws -> String {
        try await userDefaultRepository.fetchDisplayMode()
    }
    
    public func changeDisplayMode(_ mode: String) async throws {
        try await userDefaultRepository.saveDisplayMode(mode)
    }
    
    public func nextDisplayMode() async throws -> String {
        let now = try await userDefaultRepository.fetchDisplayMode()
        
        switch now {
        case "light":
            try await userDefaultRepository.saveDisplayMode("dark")
            return "dark"
        case "dark":
            try await userDefaultRepository.saveDisplayMode("")
            return ""
        default:
            try await userDefaultRepository.saveDisplayMode("light")
            return "light"
        }
    }
}
