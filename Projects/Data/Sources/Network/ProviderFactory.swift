//
//  ProviderFactory.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation
import Moya

public final class ProviderFactory {

//    private let tokenRepository: TokenRepository
//    
//    public init(tokenRepository: TokenRepository) {
//        self.tokenRepository = tokenRepository
//    }
//
//    public func makeProvider<T: TargetType>(for api: T.Type) -> BaseProvider<T> {
//        let authPlugin = AuthPlugin(tokenRepo: tokenRepository)
//
//        return BaseProvider<T>(
//            plugins: [authPlugin]
//        )
//    }
    
    public init() {}
    
    public func makeProvider<T: TargetType>(for api: T.Type) -> BaseProvider<T> {
        return BaseProvider<T>()
    }
}
