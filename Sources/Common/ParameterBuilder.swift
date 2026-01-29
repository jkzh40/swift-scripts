import Foundation

@resultBuilder
public enum ParameterBuilder {
    public static func buildBlock(_ components: (String)...) -> [String] {
        components
    }

    public static func buildOptional(_ component: [String]?) -> [String] {
        component ?? []
    }

    public static func buildEither(first component: [String]) -> [String] {
        component
    }

    public static func buildEither(second component: [String]) -> [String] {
        component
    }

    public static func buildPartialBlock(first: [String]) -> [String] {
        first
    }

    public static func buildPartialBlock(accumulated: [String], next: [String]) -> [String] {
        accumulated + next
    }

    public static func buildExpression(_ expression: String) -> [String] {
        [expression]
    }

    public static func buildArray(_ components: [[String]]) -> [String] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [String]) -> [String] {
        component
    }
}
