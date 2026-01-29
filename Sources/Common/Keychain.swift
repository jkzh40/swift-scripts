//
//  Keychain.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/14/26.
//

import Foundation

#if canImport(Security)
    import Security

    public enum Keychain {
        public static func value(for key: String, account: String) -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: key,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            guard status == errSecSuccess, let data = result as? Data else {
                return nil
            }

            return String(data: data, encoding: .utf8)
        }

        @discardableResult
        public static func store(_ key: String, value: String, account: String) -> Bool {
            delete(key, account: account)

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: key,
                kSecAttrAccount as String: account,
                kSecValueData as String: Data(value.utf8),
            ]

            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        }

        @discardableResult
        public static func delete(_ key: String, account: String) -> Bool {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: key,
                kSecAttrAccount as String: account,
            ]

            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }
    }
#endif
