//
//  NetworkExecutor.swift
//  Data
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Moya
import Combine
import Domain

protocol NetworkExecutor {
    func request<T: TargetType, R: Decodable>(_ target: T) async throws -> R
}

extension NetworkExecutor {
    func map(_ error: Error) -> NetworkError {
        if let decodingError = error as? DecodingError {
            return .decodingFailed(decodingError)
        } else if let network = error as? NetworkError {
            return network
        } else {
            return .networkFailed(error)
        }
    }
}

public final class DefaultNetworkExecutor: NetworkExecutor {
    private let providerFactory: ProviderFactory
//    private let tokenRefresher: TokenRefresher
    
    public init(providerFactory: ProviderFactory) {
        self.providerFactory = providerFactory
    }
    
    public func request<T: TargetType, R: Decodable>(_ target: T) async throws -> R {
        let provider = providerFactory.makeProvider(for: type(of: target))
        
//        do {
            return try await provider.request(target)
//        } catch let error as NetworkError {
//            // 인증 에러 발생 시 처리
//            if case .unauthorized = error,
//               let baseApi = target as? BaseAPI, baseApi.requiresAuth {
//
//                // 3. 토큰 갱신 시도
//                _ = try await tokenRefresher.refreshToken()
//
//                // 4. 딱 한 번만 더 재시도
//                return try await provider.request(target)
//            }
//            throw error
//        } catch {
//            throw error
//        }
    }
}
