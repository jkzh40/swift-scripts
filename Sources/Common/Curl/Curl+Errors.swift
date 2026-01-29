//
//  Curl+Errors.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

extension Curl {
    public enum Errors: Error, LocalizedError {
        case httpError(method: String, endpoint: String, httpCode: Int, body: String)
        case networkError(method: String, endpoint: String, curlCode: Int32, message: String)
        case timeout(method: String, endpoint: String)
        case encodingFailed

        public var errorDescription: String? {
            switch self {
            case .httpError(let method, let endpoint, let httpCode, let body):
                var message = "\(method) \(endpoint) failed: \(Self.httpMessage(for: httpCode)) (HTTP \(httpCode))"
                if !body.isEmpty {
                    message += "\nResponse: \(body.prefix(500))"
                }
                return message
            case .networkError(let method, let endpoint, _, let message):
                return "\(method) \(endpoint) failed: \(message)"
            case .timeout(let method, let endpoint):
                return "\(method) \(endpoint) failed: Operation timeout"
            case .encodingFailed:
                return "Failed to encode request body"
            }
        }

        public var httpCode: Int? {
            if case .httpError(_, _, let code, _) = self { code } else { nil }
        }

        public var responseBody: String? {
            if case .httpError(_, _, _, let body) = self { body } else { nil }
        }

        static func from(
            method: String,
            endpoint: String,
            httpCode: Int?,
            curlExitCode: Int32,
            body: String
        ) -> Errors {
            // Curl exit code errors take precedence
            if curlExitCode != 0 {
                if curlExitCode == 28 {
                    return .timeout(method: method, endpoint: endpoint)
                }
                return .networkError(
                    method: method,
                    endpoint: endpoint,
                    curlCode: curlExitCode,
                    message: curlMessage(for: curlExitCode)
                )
            }

            // HTTP error
            return .httpError(
                method: method,
                endpoint: endpoint,
                httpCode: httpCode ?? 0,
                body: body
            )
        }

        private static func httpMessage(for code: Int) -> String {
            switch code {
            case 400: "Bad Request"
            case 401: "Unauthorized"
            case 403: "Forbidden"
            case 404: "Not Found"
            case 405: "Method Not Allowed"
            case 408: "Request Timeout"
            case 409: "Conflict"
            case 410: "Gone"
            case 422: "Unprocessable Entity"
            case 429: "Too Many Requests"
            case 400...499: "Client Error"
            case 500: "Internal Server Error"
            case 501: "Not Implemented"
            case 502: "Bad Gateway"
            case 503: "Service Unavailable"
            case 504: "Gateway Timeout"
            case 500...599: "Server Error"
            default: "HTTP Error"
            }
        }

        private static func curlMessage(for exitCode: Int32) -> String {
            switch exitCode {
            case 1: "Unsupported protocol"
            case 2: "Failed to initialize"
            case 3: "URL malformed"
            case 4: "Feature not supported"
            case 5: "Couldn't resolve proxy"
            case 6: "Couldn't resolve host"
            case 7: "Failed to connect to host"
            case 16: "HTTP/2 error"
            case 18: "Partial file transfer"
            case 23: "Write error"
            case 26: "Read error"
            case 27: "Out of memory"
            case 28: "Operation timeout"
            case 33, 35, 51, 52, 53, 54, 58, 59, 60, 77, 80: "SSL/TLS error"
            case 47: "Too many redirects"
            case 55: "Network send error"
            case 56: "Network receive error"
            default: "Curl error (exit code: \(exitCode))"
            }
        }
    }
}
