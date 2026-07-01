//
//  PermissionUseCase.swift
//  Domain
//
//  Created by sanghyeon on 5/14/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol PermissionUseCase {
    func checkPermission() async throws -> PhotoPermission
    func showConsent() async throws -> Bool
    func completeConsent() async throws
    func showOnboarding() async throws -> Bool
    func completeOnboarding() async throws
    func resetForTest() async throws
}

public final class DefaultPermissionUseCase: PermissionUseCase {

    private let permissionRepository: PermissionRepository
    private let userDefaultRepository: UserDefaultRepository

    public init(permissionRepository: PermissionRepository,
                userDefaultRepository: UserDefaultRepository) {
        self.permissionRepository = permissionRepository
        self.userDefaultRepository = userDefaultRepository
    }

    public func checkPermission() async throws -> PhotoPermission {
        try await permissionRepository.checkPermission()
    }

    public func showConsent() async throws -> Bool {
        try await userDefaultRepository.showConsent()
    }

    public func completeConsent() async throws {
        try await userDefaultRepository.saveConsent(isShown: true)
    }

    public func showOnboarding() async throws -> Bool {
        try await userDefaultRepository.showOnboarding()
    }

    public func completeOnboarding() async throws {
        try await userDefaultRepository.saveOnboarding(isShown: true)
    }

    public func resetForTest() async throws {
        try await userDefaultRepository.saveConsent(isShown: false)
        try await userDefaultRepository.saveOnboarding(isShown: false)
    }
}
