//
//  GeoJsonAPI.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Moya

enum GeoJsonAPI: BaseAPI {
    
    case coordiToAddress([LocationParam])
    case coordiForOverseas([OverseasParam])
    
    public var path: String {
        switch self {
        case .coordiToAddress: return "/geo/address/kr"
        case .coordiForOverseas: return "/geo/address/overseas"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .coordiToAddress,
                .coordiForOverseas:
            return .post
        }
    }
    
    public var task: Moya.Task {
        switch self {
        case .coordiToAddress(let locations):
            let parameters = ["locations": locations]
            return .requestJSONEncodable(parameters)
        case .coordiForOverseas(let locations):
            let parameters = ["locations": locations]
            return .requestJSONEncodable(parameters)
        }
    }
}
