//
//  DefaultUserDefaultRepository.swift
//  Data
//
//  Created by sanghyeon on 5/1/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain

public final class DefaultUserDefaultRepository: UserDefaultRepository {
    
    private let service: UserDefaultsService
    
    private var now: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    init(service: UserDefaultsService) {
        self.service = service
    }
    
    public func saveAnalyzedDate() async throws {
        service.set(now, forK: UserDefaultsKey.lastAnalyzedDate)
    }
    
    public func fetchAnalyzedDate() async throws -> String {
        service.string(UserDefaultsKey.lastAnalyzedDate)
    }
    
    public func saveLocationAnalyzedDate() async throws {
        service.set(now, forK: UserDefaultsKey.lastLocationAnalyzedDate)
    }
    
    public func fetchLocationAnalyzedDate() async throws -> String {
        service.string(UserDefaultsKey.lastLocationAnalyzedDate)
    }
    
    public func saveDisplayMode(_ mode: String) async throws {
        service.set(mode, forK: UserDefaultsKey.displayMode)
    }
    
    public func fetchDisplayMode() async throws -> String {
        service.string(UserDefaultsKey.displayMode)
    }
    
    public func saveAutoNewAnalysis(isOn: Bool) async throws {
        service.set(isOn, forK: UserDefaultsKey.autoNewAnalysis)
    }
    
    public func fetchAutoNewAnalysis() async throws -> Bool? {
        service.bool(UserDefaultsKey.autoNewAnalysis)
    }
}
