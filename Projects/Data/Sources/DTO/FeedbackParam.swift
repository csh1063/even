//
//  FeedbackParam.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation

struct FeedbackParam: Encodable {
    let type: String
    let content: String
    let appVersion: String
    let buildNumber: String
    let deviceModel: String
    let osVersion: String
    let locale: String
}
