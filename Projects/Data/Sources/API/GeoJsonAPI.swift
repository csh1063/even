//
//  GeoJsonAPI.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation
import Moya

public enum GeoJsonAPI: BaseAPI {
    
    case coordiToAddress([LocationParam])
    
    public var path: String {
        switch self {
        case .coordiToAddress: return "/geo/address/kr"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .coordiToAddress: return .post
        }
    }
    
    public var task: Moya.Task {
        switch self {
        case .coordiToAddress(let locations):
            let parameters = ["locations": locations]
            return .requestJSONEncodable(parameters)
        }
    }
}
