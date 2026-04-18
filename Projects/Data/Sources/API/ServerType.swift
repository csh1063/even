//
//  ServerType.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//



import Foundation

enum ServerType {
    case dev
    case prod
    case stage
}

struct Server {
//    #if DEBUG
//    static var type: ServerType = .dev
//    #else
//    static var type: ServerType = .prod
//    #endif
    
    static var url: String {
//        switch self.type {
////        case .dev:
////        case .prod:
////        case .stage:
//        default: return "http://127.0.0.1:3000"
//        }
        return "https://mock-serverless.vercel.app/api"
//        return "http://127.0.0.1:3000"
    }
}
