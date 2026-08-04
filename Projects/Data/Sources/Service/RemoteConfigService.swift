//
//  RemoteConfigService.swift
//  Data
//
//  Created by sanghyeon on 8/3/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseInstallations

public final class RemoteConfigService {

    private struct FetchResponse: Decodable {
        let entries: [String: String]?
    }

    public init() {}

    // FirebaseRemoteConfig SDK의 fetchAndActivate()는 이 프로젝트 환경에서
    // 내부적으로 절대 완료되지 않는 프로미스 행이 있는 것으로 확인됐다(SDK 자체 버그,
    // 재현 가능: Installations 인증 토큰은 즉시 성공하지만 SDK가 자체 보유한
    // Installations 참조로 하는 동일 호출은 completion이 영영 안 옴 —
    // firebase/firebase-ios-sdk#11770과 동일 증상). 서버는 curl로 직접 확인 시
    // 정상 응답하므로, SDK를 거치지 않고 REST 엔드포인트를 직접 호출한다.
    public func fetchMinAndRecommendVersion() async throws -> (min: String, recommend: String) {
        let entries = try await fetchEntries()
        return (
            entries["ios_min_version"] ?? "",
            entries["ios_recommend_version"] ?? ""
        )
    }

    private func fetchEntries() async throws -> [String: String] {
        guard let options = FirebaseApp.app()?.options, let apiKey = options.apiKey else {
            throw URLError(.badServerResponse)
        }
        let projectNumber = options.gcmSenderID
        let appId = options.googleAppID

        let fid = try await installationID()
        let authToken = try await installationAuthToken()

        guard let url = URL(
            string: "https://firebaseremoteconfig.googleapis.com/v1/projects/\(projectNumber)/namespaces/firebase:fetch?key=\(apiKey)"
        ) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("FIREBASE_INSTALLATIONS_AUTH \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "appId": appId,
            "appInstanceId": fid,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            "packageName": Bundle.main.bundleIdentifier ?? "",
            "platformVersion": ProcessInfo.processInfo.operatingSystemVersionString
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(FetchResponse.self, from: data).entries ?? [:]
    }

    private func installationID() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Installations.installations().installationID { id, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: id ?? "")
                }
            }
        }
    }

    private func installationAuthToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Installations.installations().authToken { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result?.authToken ?? "")
                }
            }
        }
    }
}
