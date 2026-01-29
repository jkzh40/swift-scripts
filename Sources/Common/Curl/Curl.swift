//
//  Curl.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

public enum Curl {
    static let command = "curl"

    public static let acceptJsonHeader = "Accept: \(MimeType.json.rawValue)"
    public static let jsonContentTypeHeader = "Content-Type: \(MimeType.json.rawValue)"
    public static let zipMediaTypeHeader = "Media-Type: \(MimeType.zip.rawValue)"

    public static func request(
        method: String,
        endpoint: String,
        body: String?,
        headers: [String],
        credentials: String?,
        connectTimeout: Int,
        maxTime: Int,
        withStatus status: String?
    ) async throws -> String {
        let result = try await Platform.withStatus(status) {
            try await Process.run(command) {
                "-s"
                "-L"
                "-w"
                "\n%{http_code}"
                "--connect-timeout"
                "\(connectTimeout)"
                "--max-time"
                "\(maxTime)"
                "-X"
                method
                endpoint
                for header in headers {
                    "-H"
                    header
                }
                if let credentials {
                    "-u"
                    credentials
                }
                if let body {
                    "--data-raw"
                    body
                }
            }
        }

        let parsed = parseResponse(result.output, exitCode: result.exitCode)

        guard isSuccess(httpCode: parsed.httpCode, curlExitCode: parsed.curlExitCode) else {
            let error = Errors.from(
                method: method, endpoint: endpoint, httpCode: parsed.httpCode, curlExitCode: parsed.curlExitCode,
                body: parsed.body)
            Platform.error(error.localizedDescription)
            throw error
        }

        Platform.debug("Successfully completed \(method) to \(endpoint).", color: .green)
        return parsed.body
    }

    public static func head(
        endpoint: String,
        headers: [String] = [],
        credentials: String? = nil,
        connectTimeout: Int = 5,
        maxTime: Int = 10,
        withStatus status: String? = nil
    ) async throws {
        let result = try await Platform.withStatus(status) {
            try await Process.run(command) {
                "-s"
                "-I"
                "-L"
                "-w"
                "\n%{http_code}"
                "--connect-timeout"
                "\(connectTimeout)"
                "--max-time"
                "\(maxTime)"
                endpoint
                for header in headers {
                    "-H"
                    header
                }
                if let credentials {
                    "-u"
                    credentials
                }
            }
        }

        let parsed = parseResponse(result.output, exitCode: result.exitCode)

        guard isSuccess(httpCode: parsed.httpCode, curlExitCode: parsed.curlExitCode) else {
            let error = Errors.from(
                method: "HEAD", endpoint: endpoint, httpCode: parsed.httpCode, curlExitCode: parsed.curlExitCode,
                body: parsed.body)
            Platform.error(error.localizedDescription)
            throw error
        }
    }

    public static func download(
        endpoint: String,
        to destination: URL,
        headers: [String] = [],
        credentials: String? = nil,
        connectTimeout: Int = 5,
        maxTime: Int = 60,
        withStatus status: String? = nil
    ) async throws {
        let result = try await Platform.withStatus(status) {
            try await Process.run(command) {
                "-s"
                "-L"
                "-w"
                "\n%{http_code}"
                "--connect-timeout"
                "\(connectTimeout)"
                "--max-time"
                "\(maxTime)"
                "-o"
                destination.path
                endpoint
                for header in headers {
                    "-H"
                    header
                }
                if let credentials {
                    "-u"
                    credentials
                }
            }
        }

        let parsed = parseResponse(result.output, exitCode: result.exitCode)

        guard isSuccess(httpCode: parsed.httpCode, curlExitCode: parsed.curlExitCode) else {
            let error = Errors.from(
                method: "DOWNLOAD", endpoint: endpoint, httpCode: parsed.httpCode, curlExitCode: parsed.curlExitCode,
                body: parsed.body)
            Platform.error(error.localizedDescription)
            throw error
        }

        Platform.debug("Successfully downloaded to \(destination.path).", color: .green)
    }

    @discardableResult
    public static func get(
        endpoint: String,
        headers: [String] = [],
        credentials: String? = nil,
        connectTimeout: Int = 5,
        maxTime: Int = 10,
        withStatus status: String? = nil
    ) async throws -> String {
        try await request(
            method: "GET",
            endpoint: endpoint,
            body: nil,
            headers: headers,
            credentials: credentials,
            connectTimeout: connectTimeout,
            maxTime: maxTime,
            withStatus: status
        )
    }

    @discardableResult
    public static func post<T: Encodable>(
        endpoint: String,
        body: T,
        headers: [String] = [],
        credentials: String? = nil,
        connectTimeout: Int = 5,
        maxTime: Int = 10,
        withStatus status: String? = nil
    ) async throws -> String {
        guard let encodedBody = body.jsonEncoded()?.utf8String() else {
            throw Errors.encodingFailed
        }
        return try await post(
            endpoint: endpoint,
            body: encodedBody,
            headers: headers,
            credentials: credentials,
            connectTimeout: connectTimeout,
            maxTime: maxTime,
            withStatus: status
        )
    }

    @discardableResult
    public static func post(
        endpoint: String,
        body: String,
        headers: [String] = [],
        credentials: String? = nil,
        connectTimeout: Int = 5,
        maxTime: Int = 10,
        withStatus status: String? = nil
    ) async throws -> String {
        try await request(
            method: "POST",
            endpoint: endpoint,
            body: body,
            headers: headers,
            credentials: credentials,
            connectTimeout: connectTimeout,
            maxTime: maxTime,
            withStatus: status
        )
    }

    @discardableResult
    public static func put<T: Encodable>(
        endpoint: String,
        body: T,
        headers: [String] = [],
        credentials: String? = nil,
        connectTimeout: Int = 5,
        maxTime: Int = 10,
        withStatus status: String? = nil
    ) async throws -> String {
        guard let encodedBody = body.jsonEncoded()?.utf8String() else {
            throw Errors.encodingFailed
        }
        return try await put(
            endpoint: endpoint,
            body: encodedBody,
            headers: headers,
            credentials: credentials,
            connectTimeout: connectTimeout,
            maxTime: maxTime,
            withStatus: status
        )
    }

    @discardableResult
    public static func put(
        endpoint: String,
        body: String,
        headers: [String] = [],
        credentials: String? = nil,
        connectTimeout: Int = 5,
        maxTime: Int = 10,
        withStatus status: String? = nil
    ) async throws -> String {
        try await request(
            method: "PUT",
            endpoint: endpoint,
            body: body,
            headers: headers,
            credentials: credentials,
            connectTimeout: connectTimeout,
            maxTime: maxTime,
            withStatus: status
        )
    }

    private static func parseResponse(_ output: String, exitCode: Int32) -> (
        body: String, httpCode: Int?, curlExitCode: Int32
    ) {
        // If curl itself failed (network error, timeout, etc.), return the exit code
        guard exitCode == 0 else {
            return (output, nil, exitCode)
        }

        // Parse the HTTP status code from the last line (added by -w "\n%{http_code}")
        let lines = output.components(separatedBy: "\n")
        guard let httpCodeString = lines.last, let httpCode = Int(httpCodeString) else {
            return (output, nil, 0)
        }

        // Response body is everything except the last line (HTTP code)
        let body = lines.dropLast().joined(separator: "\n")
        return (body, httpCode, 0)
    }

    private static func isSuccess(httpCode: Int?, curlExitCode: Int32) -> Bool {
        curlExitCode == 0 && httpCode.map { (200...299).contains($0) } == true
    }
}
