//
//  AppVersionPolicy.swift
//  Domain
//
//  Created by sanghyeon on 8/3/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

public struct AppVersionPolicy {
    public let minVersion: String
    public let recommendVersion: String

    public init(minVersion: String, recommendVersion: String) {
        self.minVersion = minVersion
        self.recommendVersion = recommendVersion
    }
}
