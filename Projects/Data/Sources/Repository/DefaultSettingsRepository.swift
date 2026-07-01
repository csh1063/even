//
//  DefaultSettingsRepository.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Domain
import UIKit

public final class DefaultSettingsRepository: SettingsRepository {

    private let service: NetworkService

    public init(service: NetworkService) {
        self.service = service
    }

    public func writeFeedback(type: String, content: String) async throws {

        let param = await FeedbackParam(
            type: type,
            content: content,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "",
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            locale: Locale.current.identifier
        )

        return try await service.writeFeedback(param)
    }
}
