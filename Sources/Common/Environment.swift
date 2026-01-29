import Foundation

#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

@propertyWrapper
public struct Environment {
    private let key: String
    private let defaultValue: String?

    public init(_ key: String, default defaultValue: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: String? {
        ProcessInfo.processInfo.environment[key] ?? defaultValue
    }
}

extension Environment {
    public static func value(for key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }

    @discardableResult
    public static func store(_ key: String, value: String, overwrite: Bool = true) -> Bool {
        setenv(key, value, overwrite ? 1 : 0) == 0
    }

    public static func remove(_ key: String) {
        unsetenv(key)
    }
}

extension Environment {
    public static var username: String {
        value(for: "USER") ?? "unknown"
    }
}
