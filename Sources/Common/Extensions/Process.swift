//
//  Process.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/12/26.
//

import Foundation

extension Process {
    @discardableResult
    public static func run(
        _ command: String,
        args: [String] = []
    ) async throws -> (output: String, exitCode: Int32) {
        Platform.debug("Running: \(command)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        let data = try await pipe.fileHandleForReading.bytes.reduce(into: Data()) { $0.append($1) }

        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""
        let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)

        for line in output.separatedByNewLines {
            Platform.debug(line)
        }

        Platform.debug("Exit Code: \(process.terminationStatus)")

        return (trimmedOutput, process.terminationStatus)
    }

    @discardableResult
    public static func run(
        _ command: String,
        @ParameterBuilder args: () async throws -> [String]
    ) async throws -> (output: String, exitCode: Int32) {
        try await run(command, args: args())
    }
}
