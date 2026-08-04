//
//  KeychainService.swift
//  Data
//
//  Created by sanghyeon on 8/4/26.
//  Copyright © 2026 sanghyeon. All rights reserved.
//

import Foundation
import Security

// 앱을 삭제했다 재설치해도 값이 남아있어야 하는 용도(예: 무료 시절 사용 이력)로 쓴다.
// UserDefaults는 앱 삭제 시 같이 지워지지만, Keychain은 기기 자체를 초기화하지 않는 한 유지된다.
public final class KeychainService {

    public init() {}

    public func set(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    public func string(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
