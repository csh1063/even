//
//  BaseAPI.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//



import UIKit
import Moya

public protocol BaseAPI: TargetType {
    var requiresAuth: Bool { get }
}

extension BaseAPI {
    public var baseURL: URL {
        guard let url = URL(string: Server.url) else {
            fatalError("\(Server.url)")
        }
        
        return url
    }
    
    public var headers: [String: String]? {
//        let info = Bundle.main.infoDictionary
//        let appVersion = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
//        let version = ProcessInfo.processInfo.operatingSystemVersion
//        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let header: [String: String] = ["LoggerKey": "\(Date()) \(Date().timeIntervalSince1970)"]
//        header["Authorization"] = "Bearer \(LoginUsersData.shared.accessToken)"
//        header["userDeviceInfo"] = "iOS(\(appVersion); \(UIDevice.modelName); \(versionString))"
        
        return header
    }
    
    public var validationType: ValidationType {
        return .successCodes
    }
    
    public var requiresAuth: Bool { return false }
}
