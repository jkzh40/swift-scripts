//
//  Jira+Errors.swift
//  SwiftScripts
//

import Foundation

extension Jira {
    public enum Errors: Error, LocalizedError {
        case notConnected(baseURL: String, underlyingError: String)
        case requestFailed(endpoint: String, underlyingError: String)
        case decodingFailed(type: String, output: String)
        case invalidResponse(message: String)

        public var errorDescription: String? {
            switch self {
            case .notConnected(let baseURL, let underlyingError):
                return "Failed to connect to Jira at \(baseURL): \(underlyingError)"
            case .requestFailed(let endpoint, let underlyingError):
                return "Jira request to \(endpoint) failed: \(underlyingError)"
            case .decodingFailed(let type, let output):
                return "Failed to decode \(type) from response: \(output.prefix(200))"
            case .invalidResponse(let message):
                return message
            }
        }
    }
}
