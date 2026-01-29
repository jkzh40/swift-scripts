//
//  AsyncCommand.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/9/26.
//

import ArgumentParser
import Figlet
import Foundation

public protocol AsyncCommand: AsyncParsableCommand {
    static var banner: String? { get }
    var logLevel: Platform.LogLevel { get }
    var logFile: URL? { get }
    mutating func run() async throws
}

extension AsyncCommand {
    public static var banner: String? { nil }

    public var logLevel: Platform.LogLevel { .info }

    public var logFile: URL? { Self.defaultLog() }

    /// Executes this command, or one of its subcommands, with the given arguments.
    ///
    /// This method parses an instance of this type, one of its subcommands, or
    /// another built-in `AsyncParsableCommand` type, from command-line
    /// (or provided) arguments, and then calls its `run()` method, exiting
    /// with a relevant error message if necessary.
    ///
    /// - Parameter arguments: An array of arguments to use for parsing. If
    ///   `arguments` is `nil`, this uses the program's command-line arguments.
    public static func main(_ arguments: [String]?) async {
        do {
            var command = try parseAsRoot(arguments)

            if var asyncCommand = command as? AsyncCommand {
                let logFile = asyncCommand.logFile
                let logLevel = asyncCommand.logLevel

                let stream: FileHandle? = {
                    guard let logFile else { return nil }
                    fileManager.createFile(atPath: logFile.path, contents: nil)
                    return try? FileHandle(forWritingTo: logFile)
                }()

                defer { try? stream?.close() }

                try await Platform.$outputStream.withValue(stream) {
                    try await Platform.$logLevel.withValue(logLevel) {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .medium

                        if let banner {
                            Platform.log(Figlet.render(banner, boxed: true))
                        }

                        Platform.log("Command:      \(Self._commandName)", color: .yellow)
                        Platform.log(
                            "Arguments:    \(CommandLine.arguments.dropFirst().joined(separator: " "))",
                            color: .yellow)
                        Platform.log("Date:         \(formatter.string(from: Date()))", color: .yellow)
                        if let logFile {
                            Platform.log("Log:          \(logFile.path)", color: .yellow)
                        }
                        Platform.log()
                        try await asyncCommand.run()
                    }
                }
            } else if var asyncCommand = command as? AsyncParsableCommand {
                try await asyncCommand.run()
            } else {
                try command.run()
            }
        } catch {
            exit(withError: error)
        }
    }

    /// Executes this command, or one of its subcommands, with the program's
    /// command-line arguments.
    ///
    /// Instead of calling this method directly, you can add `@main` to the root
    /// command for your command-line tool.
    ///
    /// This method parses an instance of this type, one of its subcommands, or
    /// another built-in `AsyncParsableCommand` type, from command-line arguments,
    /// and then calls its `run()` method, exiting with a relevant error message
    /// if necessary.
    public static func main() async {
        await self.main(nil)
    }
}

// MARK: Platform
extension AsyncCommand {
    public typealias Colors = Platform.Colors
    public typealias LogLevel = Platform.LogLevel

    public func clear() {
        Platform.clear()
    }

    public func log(
        _ item: String = "", terminator: String = "\n", color: Colors? = nil, level: LogLevel = .info
    ) {
        Platform.log(item, terminator: terminator, color: color, level: level)
    }

    public func section(_ header: String, color: Colors? = nil) {
        Platform.section(header, color: color)
    }

    public func debug(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        Platform.debug(item, terminator: terminator, color: color)
    }

    public func info(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        Platform.info(item, terminator: terminator, color: color)
    }

    public func warn(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        Platform.warn(item, terminator: terminator, color: color)
    }

    public func error(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        Platform.error(item, terminator: terminator, color: color)
    }

    @discardableResult
    public func prompt(_ prompt: String, color: Colors? = nil) -> String? {
        Platform.prompt(prompt, color: color)
    }

    @discardableResult
    public func securePrompt(_ prompt: String, color: Colors? = nil) -> String? {
        Platform.securePrompt(prompt, color: color)
    }

    @discardableResult
    public func withStatus<T>(
        _ status: String?, color: Colors? = nil, operation: () async throws -> T
    ) async rethrows -> T {
        try await Platform.withStatus(status, color: color, operation: operation)
    }

    @discardableResult
    public func withProgressBar<T>(
        _ percentage: @escaping () -> Double, color: Colors = .cyan, operation: () async -> T
    ) async -> T {
        await Platform.withProgressBar(percentage, color: color, operation: operation)
    }

    public func exit(_ code: Int32) -> Never {
        Platform.exit(code)
    }

    public func exit(_ code: ExitCode) -> Never {
        Platform.exit(code)
    }

    public func exit(_ messages: [String]) -> Never {
        Platform.exit(messages)
    }

    public func exit(_ messages: String...) -> Never {
        Platform.exit(messages)
    }

    public func fail(_ messages: [String]) -> Never {
        Platform.fail(messages)
    }

    public static func fail(_ messages: String...) -> Never {
        Platform.fail(messages)
    }
}

// MARK: Process
extension AsyncCommand {
    @discardableResult
    public func run(_ command: String, args: [String] = []) async throws -> (
        output: String, exitCode: Int32
    ) {
        try await Process.run(command, args: args)
    }

    @discardableResult
    public func run(_ command: String, @ParameterBuilder args: () async throws -> [String])
        async throws -> (output: String, exitCode: Int32)
    {
        try await Process.run(command, args: args)
    }

    public func open(url: String) async {
        _ = try? await run("open") { url }
    }

    public func unzip(_ file: String, to path: String) async {
        _ = try? await run("unzip", args: [file, "-d", path])
    }
}

// MARK: FileManager
extension AsyncCommand {
    public static var fileManager: FileManager { .default }

    public static func defaultLog() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = formatter.string(from: Date())
        return fileManager.pwd.appendingPathComponent("\(_commandName)_\(timestamp).log")
    }

    public var pwd: URL {
        Self.fileManager.pwd
    }

    public func ls(_ path: String) throws -> [String] {
        try Self.fileManager.ls(path)
    }

    public func ls(_ url: URL) throws -> [String] {
        try Self.fileManager.ls(url)
    }

    public func ls(_ url: URL, fullPaths: Bool) throws -> [URL] {
        try Self.fileManager.ls(url, fullPaths: fullPaths)
    }

    public func mkdir(_ path: String, withIntermediateDirectories: Bool = true) throws {
        try Self.fileManager.mkdir(path, withIntermediateDirectories: withIntermediateDirectories)
    }

    public func mkdir(_ url: URL, withIntermediateDirectories: Bool = true) throws {
        try Self.fileManager.mkdir(url, withIntermediateDirectories: withIntermediateDirectories)
    }
}
