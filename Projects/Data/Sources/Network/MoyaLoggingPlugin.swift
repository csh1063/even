//
//  MoyaLoggingPlugin.swift
//  Data
//
//  Created by sanghyeon on 9/5/25.
//

import Foundation
import Moya
import Domain

final class MoyaLoggingPlugin: PluginType {

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        request
    }

    func willSend(_ request: RequestType, target: TargetType) {
        var log = "👉 NETWORK Request: " + (request.request?.url?.absoluteString ?? "") + "\n"
        log += "* Method: " + (request.request?.httpMethod ?? "") + "\n"

        if let header = request.request?.allHTTPHeaderFields {
            log += "* Headers: \(header)\n"
        }
        if let body = request.request?.httpBody {
            log += "* Body: " + (body.toPrettyPrintedString ?? "")
        }

        debugLog(log)
    }

    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            debugLog("""
            ✊ NETWORK Response: \(response.request?.url?.absoluteString ?? "")
            * StatusCode: \(response.response?.statusCode ?? 0)
            * Data: \(response.data.toPrettyPrintedString ?? "")
            """)

        case .failure(let failure):
            debugLog("""
            ✊ NETWORK Response 실패: \(failure.localizedDescription)
            * Data: \(failure.response?.data.toPrettyPrintedString ?? "")
            """)
        }
    }

    func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
        result
    }

    func onFail(_ error: MoyaError, target: TargetType) {
        debugLog("""
        네트워크 오류: \(error.errorCode) \(target)
        \(error.failureReason ?? error.errorDescription ?? "unknown error")
        targetURL: \(target.path), targetTask: \(target.task)
        """)
    }
}

extension Data {
    var toPrettyPrintedString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        return prettyPrintedString as String
    }
}
