//
//  GH+Errors.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

extension GH {
    public enum Errors: Error, LocalizedError {
        case notInstalled
        case notAuthenticated
        case commandFailed(command: String, exitCode: Int32, output: String)
        case decodingFailed(type: String, output: String)
        case invalidResponse(message: String)

        public var errorDescription: String? {
            switch self {
            case .notInstalled:
                return "GitHub CLI (gh) is not installed. Use 'brew install gh' to install."
            case .notAuthenticated:
                return "Not authenticated with GitHub CLI. Use 'gh auth login' to authenticate."
            case .commandFailed(let command, let exitCode, let output):
                var message = "gh \(command) failed (exit code \(exitCode))"
                if !output.isEmpty {
                    message += "\nOutput: \(output.prefix(500))"
                }
                return message
            case .decodingFailed(let type, let output):
                return "Failed to decode \(type) from response: \(output.prefix(200))"
            case .invalidResponse(let message):
                return message
            }
        }
    }
}
