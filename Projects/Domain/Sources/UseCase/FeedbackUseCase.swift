//
//  FeedbackUseCase.swift
//  Domain
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public protocol FeedbackUseCase {
    func writeFeedback(type: String, content: String) async throws
}

public final class DefaultFeedbackUseCase: FeedbackUseCase {
    
    private let repository: SettingsRepository
    
    public init(repository: SettingsRepository) {
        self.repository = repository
    }
    
    public func writeFeedback(type: String, content: String) async throws {
        try await repository.writeFeedback(type: type, content: content)
    }
}
