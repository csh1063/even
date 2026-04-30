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
    
    init(service: UserDefaultsService) {
        self.service = service
    }
    
    public func saveAnalyzedDate() async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        service.set(formatter.string(from: Date()), forK: UserDefaultsKey.lastAnalyzedDate)
    }
    
    public func fetchAnalyzedDate() async throws -> String {
        service.string(UserDefaultsKey.lastAnalyzedDate)
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
