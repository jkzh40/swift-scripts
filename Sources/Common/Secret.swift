//
//  Secret.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/12/26.
//

import Foundation

@propertyWrapper
public struct Secret {
    private let key: String
    private let prompt: String
    private let account: String

    public init(key: String, prompt: String? = nil) {
        self.key = key
        self.prompt = prompt ?? "Enter your \(key)"
        self.account = Environment.username
    }

    public var wrappedValue: String {
        if let secret = Environment.value(for: key), !secret.isEmpty {
            return secret
        }

        #if canImport(Security)
            if let secret = Keychain.value(for: key, account: account) {
                return secret
            }
        #endif

        Platform.warn("\(key) is required to trigger release automation.")

        guard let secret = Platform.securePrompt(prompt, color: .green),
            !secret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            Platform.fail("No \(key) provided. Secret is required to continue with release automation.")
        }

        let cleanSecret = secret.trimmingCharacters(in: .whitespacesAndNewlines)

        #if canImport(Security)
            if Keychain.store(key, value: cleanSecret, account: account) {
                Platform.info("Secret saved securely in Keychain for future use.")
            } else {
                Platform.warn(
                    "Could not save secret to Keychain. You may need to enter it again next time.")
            }
        #else
            if Environment.store(key, value: cleanSecret) {
                Platform.info("Secret saved in Environment for this session.")
            } else {
                Platform.warn("Could not save secret to Environment.")
            }
        #endif

        return cleanSecret
    }
}
