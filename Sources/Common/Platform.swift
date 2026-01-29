//
//  Platform.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/12/26.
//

import Foundation

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

public enum Platform {}

extension Platform {
    private static var isatty: Bool = {
        #if canImport(Glibc)
            guard Glibc.isatty(STDOUT_FILENO) != 0 else { return false }
        #elseif canImport(Musl)
            guard Musl.isatty(STDOUT_FILENO) != 0 else { return false }
        #elseif canImport(Darwin)
            guard Darwin.isatty(STDOUT_FILENO) != 0 else { return false }
        #endif
        return ProcessInfo.processInfo.environment["TERM"] != "dumb"
    }()

    public static func exit(_ code: Int32) -> Never {
        #if canImport(Glibc)
            Glibc.exit(code)
        #elseif canImport(Musl)
            Musl.exit(code)
        #elseif canImport(Darwin)
            Darwin.exit(code)
        #endif
    }
}

extension Platform {
    @TaskLocal static var outputStream: FileHandle?
    @TaskLocal static var logLevel: LogLevel = .info

    public static func print(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        if let color, isatty {
            Swift.print("\(color.rawValue)\(item)\(Colors.reset.rawValue)", terminator: terminator)
        } else {
            Swift.print(item, terminator: terminator)
        }
    }

    public static func clear() {
        guard isatty else { return }
        Swift.print("\r\u{001B}[K", terminator: "")
        fflush(stdout)
    }

    public static func log(
        _ item: String = "", terminator: String = "\n", color: Colors? = nil, level: LogLevel = .info
    ) {
        guard logLevel.rawValue <= level.rawValue else { return }
        clear()
        print(item, terminator: terminator, color: color ?? level.color)
        try? outputStream?.write(contentsOf: Data((item + terminator).utf8))
    }

    public static func section(_ header: String, color: Colors? = nil) {
        let color = color ?? .magenta
        let divider = String(repeating: "─", count: 50)
        log("")
        log("▶ \(header)", color: color)
        log(divider, color: color)
    }

    public static func debug(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        log(item, terminator: terminator, color: color, level: .debug)
    }

    public static func info(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        log(item, terminator: terminator, color: color, level: .info)
    }

    public static func warn(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        log(item, terminator: terminator, color: color, level: .warning)
    }

    public static func error(_ item: String = "", terminator: String = "\n", color: Colors? = nil) {
        log(item, terminator: terminator, color: color, level: .error)
    }

    @discardableResult
    public static func prompt(_ prompt: String, color: Colors? = nil) -> String? {
        log(prompt, terminator: ": ", color: color)
        let input = readLine()
        if let input { log(input) }
        return input
    }

    @discardableResult
    public static func securePrompt(_ prompt: String, color: Colors? = nil) -> String? {
        log(prompt, terminator: ": ", color: color)

        let fileHandle = FileHandle.standardInput
        let originalTermSettings = UnsafeMutablePointer<termios>.allocate(capacity: 1)
        defer { originalTermSettings.deallocate() }

        // Get current terminal settings
        if tcgetattr(fileHandle.fileDescriptor, originalTermSettings) == -1 {
            fail("Error: Failed to get terminal attributes")
        }

        // Create new settings with echo disabled
        var newTermSettings = originalTermSettings.pointee
        newTermSettings.c_lflag &= ~tcflag_t(ECHO)

        // Apply the new settings
        tcsetattr(fileHandle.fileDescriptor, TCSANOW, &newTermSettings)

        // Read the input
        let input = readLine()

        // Restore original settings
        tcsetattr(fileHandle.fileDescriptor, TCSANOW, originalTermSettings)

        // Print a newline since echo was disabled
        log("")

        return input
    }

    public enum Colors: String {
        case red = "\u{001B}[31m"
        case green = "\u{001B}[32m"
        case yellow = "\u{001B}[33m"
        case blue = "\u{001B}[34m"
        case magenta = "\u{001B}[35m"
        case cyan = "\u{001B}[36m"
        case white = "\u{001B}[37m"
        case reset = "\u{001B}[0m"
    }

    public enum LogLevel: Int {
        case debug
        case info
        case warning
        case error

        var color: Platform.Colors {
            switch self {
            case .debug: .cyan
            case .info: .white
            case .warning: .yellow
            case .error: .red
            }
        }
    }
}

extension Platform {
    public static func status(_ status: String?, color: Colors? = nil) async {
        let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        var frameIndex = 0

        guard let status else { return }

        guard isatty else {
            print(status, color: color)
            return
        }

        while !Task.isCancelled {
            clear()
            print("\(frames[frameIndex % frames.count]) \(status)", terminator: "", color: color)
            fflush(stdout)
            frameIndex += 1

            try? await Task.sleep(for: .seconds(0.1))
        }
    }

    @discardableResult
    public static func withStatus<T>(
        _ status: String?, color: Colors? = nil, operation: () async throws -> T
    ) async rethrows -> T {
        let statusTask: Task<Void, Never>? = Task {
            await self.status(status, color: color)
        }
        defer {
            statusTask?.cancel()
            if status != nil {
                clear()
            }
        }
        return try await operation()
    }

    public static func progress(percentage: @escaping () -> Double, color: Colors = .cyan) async {
        guard isatty else { return }
        while !Task.isCancelled {
            let currentPercentage = percentage()
            let clampedPercentage = max(0, min(100, currentPercentage))
            let barWidth = 50
            let filledWidth = Int((clampedPercentage / 100.0) * Double(barWidth))
            let emptyWidth = barWidth - filledWidth

            let filledBar = String(repeating: "█", count: filledWidth)
            let emptyBar = String(repeating: "░", count: emptyWidth)

            clear()
            print(
                "[\(filledBar)\(emptyBar)] \(String(format: "%.1f", clampedPercentage))%", terminator: "",
                color: color)
            fflush(stdout)

            if clampedPercentage >= 100 {
                break
            }

            try? await Task.sleep(for: .seconds(0.1))
        }
    }

    @discardableResult
    public static func withProgressBar<T>(
        _ percentage: @escaping () -> Double, color: Colors = .cyan, operation: () async -> T
    ) async -> T {
        let statusTask: Task<Void, Never>? = Task {
            await progress(percentage: percentage, color: color)
        }
        defer {
            statusTask?.cancel()
            clear()
        }
        return await operation()
    }
}

extension Platform {
    public static func exit(_ code: ExitCode) -> Never {
        exit(code.rawValue)
    }

    public static func exit(_ messages: [String]) -> Never {
        for message in messages {
            info(message)
        }
        exit(.success)
    }

    public static func exit(_ messages: String...) -> Never {
        exit(messages)
    }

    public static func fail(_ messages: [String]) -> Never {
        for message in messages {
            error(message)
        }
        exit(.failure)
    }

    public static func fail(_ messages: String...) -> Never {
        fail(messages)
    }
}
