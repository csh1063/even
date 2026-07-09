//
//  SettingAPI.swift
//  Data
//
//  Created by sanghyeon on 5/18/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Moya

enum SettingAPI: BaseAPI {

    case feedback(FeedbackParam)

    public var path: String {
        switch self {
        case .feedback: return "/contact/feedback"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .feedback: return .post
        }
    }

    public var task: Moya.Task {
        switch self {
        case .feedback(let parameters):

            return .requestJSONEncodable(parameters)
        }
    }
}
