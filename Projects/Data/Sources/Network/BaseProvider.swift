//
//  BaseProvider.swift
//  Data
//
//  Created by sanghyeon on 9/5/25.
//

import Moya
import Foundation
import Domain

public final class BaseProvider<U: TargetType>: MoyaProvider<U> {
    
    public init(
        endpointClosure: @escaping EndpointClosure = MoyaProvider.defaultEndpointMapping,
        stubClosure: @escaping StubClosure = MoyaProvider.neverStub,
        plugins: [PluginType] = []
    ) {
        let session = Moya.Session()
        var newPlugins = plugins
        newPlugins.append(MoyaLoggingPlugin())
        super.init(session: session, plugins: newPlugins)
    }

    func asyncRequest(_ target: U) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func request<T: Decodable>(_ target: U) async throws -> T {
        do {
            let response = try await self.asyncRequest(target)
            let decoded = try JSONDecoder().decode(BaseDTO<T>.self, from: response.data)
            
            guard let data = decoded.data else {
                throw NetworkError.invalidResponse
            }
            
            return data
        } catch let error as DecodingError {
            throw NetworkError.decodingFailed(error)
        } catch {
            throw NetworkError.networkFailed(error)
        }
    }
}
