//
//  NetworkError.swift
//  Domain
//
//  Created by sanghyeon on 4/11/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//


import Foundation

public enum NetworkError: Error {
    case urlError
    case networkFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .urlError: return "URL 오류"
        case .networkFailed(let error): return "네트워크 실패: \(error.localizedDescription)"
        case .invalidResponse: return "잘못된 응답"
        case .decodingFailed(let error): return "디코딩 실패: \(error.localizedDescription)"
        }
    }
}


public enum SwiftDataError: Error {
    //    SwiftData CRUD 실패
    //    마이그레이션 실패
    //    PHImageManager 로드 실패
    //    Photos 권한 없음
    case swiftDataFailed(Error)
}

extension SwiftDataError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .swiftDataFailed(let error): return "SwiftData 로딩 실패: \(error.localizedDescription)"
        }
    }
}

public enum DomainError: Error {
//    폴더 생성/삭제/조회 실패
//    자동 분류 실패 (AutoFolderUseCase)
//    지오코딩 실패
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        }
    }
}
