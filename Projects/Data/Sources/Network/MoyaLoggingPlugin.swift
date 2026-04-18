//
//  MoyaLoggingPlugin.swift
//  Data
//
//  Created by sanghyeon on 9/5/25.
//

import Foundation
import Moya

final class MoyaLoggingPlugin: PluginType {
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        
        print("")
        print("prepare")
        
        return request
    }
    
    func willSend(_ request: RequestType, target: TargetType) {
        
        print("")
        print("willSend")
        
        print("👉 NETWORK Reqeust LOG start =====================================")
//        print(request.description)
        print("* URL: " + (request.request?.url?.absoluteString ?? ""))
        print("* Method: " + (request.request?.httpMethod ?? ""))
        
        if let header = request.request?.allHTTPHeaderFields {
            
            print("* Headers: [")
            
//            if let configHeader = request.request?.headers {
//                for (key, value) in configHeader.dictionary {
//                    print("\t\(key): \(value)")
//                }
//            }
            for (key, value) in header {
                print("\t\(key): \(value)")
            }
            print("]")
        }

        if let body = request.request?.httpBody {
            print("* Body: " + (body.toPrettyPrintedString ?? ""))
        }
        
        print("👉 NETWORK Reqeust LOG end   =====================================")
    }
    
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        
        print("")
        print("didReceive")
        
        print("✊ NETWORK Response LOG start ====================================")
        
        switch result {
        case .success(let response):
            if let header = response.request?.allHTTPHeaderFields,
               let loggerTime = header["LoggerKey"],
               let last = loggerTime.components(separatedBy: " ").last,
               let timeInterval = TimeInterval(last) {
                let executionTime = Date().timeIntervalSince1970 - timeInterval
                print("* Request Time: \(loggerTime.components(separatedBy: " ").dropLast().joined(separator: " "))")
                print("* Response Time: \(Date()) \(executionTime)")
            }
            
            print("* URL: " + (response.request?.url?.absoluteString ?? ""))
            print("* Result: SUCCESS")
            print("* StatusCode: " + "\(response.response?.statusCode ?? 0)")
            print("* Data: \(response.data.toPrettyPrintedString ?? "")")

        case .failure(let failure):
            print("* Error: \(failure.localizedDescription)")
            print("* Data: \(failure.response?.data.toPrettyPrintedString ?? "")")
        }
        
        print("✊ NETWORK Response LOG end   ====================================")
        
    }
    
    func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
        
//        print("process")
//        
//        let _ = result.map { response in
//            print("process: \(response.data.toPrettyPrintedString ?? "")")
//        }
        
        return result
    }
    
    
    func onFail(_ error: MoyaError, target: TargetType) {
        var log = "DEBUG - <네트워크 오류> ------------ "
        log.append("DEBUG - <----- \(error.errorCode) \(target) -----> \n")
        log.append("DEBUG - \(error.failureReason ?? error.errorDescription ?? "unknown error")\n")
        log.append("DEBUG - targetURL: \(target.path)\n")
        log.append("DEBUG - targetTask: \(target.task)\n")
        log.append("DEBUG - <---- End Log ---->")
        print(log)
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
