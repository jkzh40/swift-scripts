import ArgumentParser
import Foundation
import Testing

@testable import Common

@Suite("Common Tests")
struct CommonTests {

    // MARK: - String Extension Tests

    @Suite("String Extensions")
    struct StringExtensionTests {

        @Test("newLine static property returns newline character")
        func newLineProperty() {
            #expect(String.newLine == "\n")
        }

        @Test("separatedByNewLines splits string correctly")
        func separatedByNewLines() {
            let input = "line1\nline2\nline3"
            let result = input.separatedByNewLines
            #expect(result == ["line1", "line2", "line3"])
        }

        @Test("separatedByNewLines filters empty lines")
        func separatedByNewLinesFiltersEmpty() {
            let input = "line1\n\nline2\n\nline3"
            let result = input.separatedByNewLines
            #expect(result == ["line1", "line2", "line3"])
        }

        @Test("separatedByNewLines handles single line")
        func separatedByNewLinesSingleLine() {
            let input = "single"
            let result = input.separatedByNewLines
            #expect(result == ["single"])
        }

        @Test("mappedLines transforms each line")
        func mappedLines() {
            let input = "a\nb\nc"
            let result = input.mappedLines { $0.uppercased() }
            #expect(result == "A\nB\nC")
        }

        @Test("Valid semantic versions are recognized")
        func validSemanticVersions() {
            #expect("1.0.0".isValidSemanticVersion)
            #expect("0.0.1".isValidSemanticVersion)
            #expect("12.34.56".isValidSemanticVersion)
            #expect("1.0.0-alpha".isValidSemanticVersion)
            #expect("2.1.3-beta".isValidSemanticVersion)
        }

        @Test("Invalid semantic versions are rejected")
        func invalidSemanticVersions() {
            #expect(!"1.0".isValidSemanticVersion)
            #expect(!"1".isValidSemanticVersion)
            #expect(!"1.0.0.0".isValidSemanticVersion)
            #expect(!"v1.0.0".isValidSemanticVersion)
            #expect(!"1.0.0-".isValidSemanticVersion)
            #expect(!"abc".isValidSemanticVersion)
            #expect(!"".isValidSemanticVersion)
        }
    }

    // MARK: - Array Extension Tests

    @Suite("Array Extensions")
    struct ArrayExtensionTests {

        @Test("joinedWithNewLines joins strings with newlines")
        func joinedWithNewLines() {
            let input = ["a", "b", "c"]
            #expect(input.joinedWithNewLines == "a\nb\nc")
        }

        @Test("joinedWithNewLines handles empty array")
        func joinedWithNewLinesEmpty() {
            let input: [String] = []
            #expect(input.joinedWithNewLines == "")
        }

        @Test("joinedWithNewLines handles single element")
        func joinedWithNewLinesSingle() {
            let input = ["only"]
            #expect(input.joinedWithNewLines == "only")
        }
    }

    // MARK: - JSON Encoding/Decoding Tests

    @Suite("JSON Extensions")
    struct JSONExtensionTests {

        struct TestModel: Codable, Equatable {
            let name: String
            let value: Int
        }

        @Test("Encodable jsonEncoded returns valid data")
        func jsonEncoded() {
            let model = TestModel(name: "test", value: 42)
            let data = model.jsonEncoded()
            #expect(data != nil)
        }

        @Test("Data utf8String converts to string")
        func utf8String() {
            let string = "Hello, World!"
            let data = string.data(using: .utf8)!
            #expect(data.utf8String() == "Hello, World!")
        }

        @Test("Data jsonDecoded decodes valid JSON")
        func jsonDecoded() {
            let model = TestModel(name: "test", value: 42)
            let data = model.jsonEncoded()!
            let decoded: TestModel? = data.jsonDecoded()
            #expect(decoded == model)
        }

        @Test("Data jsonDecoded returns nil for invalid JSON")
        func jsonDecodedInvalid() {
            let invalidData = "not json".data(using: .utf8)!
            let decoded: TestModel? = invalidData.jsonDecoded()
            #expect(decoded == nil)
        }

        @Test("Round-trip encoding and decoding preserves data")
        func roundTrip() {
            let original = TestModel(name: "round-trip", value: 123)
            let encoded = original.jsonEncoded()!
            let decoded: TestModel = encoded.jsonDecoded()!
            #expect(decoded == original)
        }
    }

    // MARK: - ParameterBuilder Tests

    @Suite("ParameterBuilder")
    struct ParameterBuilderTests {

        @Test("Builds simple parameter list")
        func simpleList() {
            @ParameterBuilder
            func build() -> [String] {
                "one"
                "two"
                "three"
            }
            #expect(build() == ["one", "two", "three"])
        }

        @Test("Handles optional parameters when present")
        func optionalPresent() {
            let includeOptional = true
            @ParameterBuilder
            func build() -> [String] {
                "required"
                if includeOptional {
                    "optional"
                }
            }
            #expect(build() == ["required", "optional"])
        }

        @Test("Handles optional parameters when absent")
        func optionalAbsent() {
            let includeOptional = false
            @ParameterBuilder
            func build() -> [String] {
                "required"
                if includeOptional {
                    "optional"
                }
            }
            #expect(build() == ["required"])
        }

        @Test("Handles if-else conditions")
        func ifElseCondition() {
            let useFirst = true
            @ParameterBuilder
            func buildFirst() -> [String] {
                if useFirst {
                    "first"
                } else {
                    "second"
                }
            }

            let useSecond = false
            @ParameterBuilder
            func buildSecond() -> [String] {
                if useSecond {
                    "first"
                } else {
                    "second"
                }
            }

            #expect(buildFirst() == ["first"])
            #expect(buildSecond() == ["second"])
        }

        @Test("Handles for-in loops")
        func forInLoop() {
            let items = ["a", "b", "c"]
            @ParameterBuilder
            func build() -> [String] {
                for item in items {
                    item
                }
            }
            #expect(build() == ["a", "b", "c"])
        }

        @Test("Combines multiple features")
        func combinedFeatures() {
            let verbose = true
            let extras = ["x", "y"]
            @ParameterBuilder
            func build() -> [String] {
                "base"
                if verbose {
                    "--verbose"
                }
                for extra in extras {
                    extra
                }
            }
            #expect(build() == ["base", "--verbose", "x", "y"])
        }
    }

    // MARK: - Property Name Formatting Tests

    @Suite("Property Name Formatting")
    struct PropertyNameFormattingTests {

        @Test("Converts camelCase to Title Case")
        func camelCaseToTitleCase() {
            #expect("nonInteractive".formattedPropertyName == "Non Interactive")
            #expect("dryRun".formattedPropertyName == "Dry Run")
            #expect("verbose".formattedPropertyName == "Verbose")
        }

        @Test("Handles single word")
        func singleWord() {
            #expect("silent".formattedPropertyName == "Silent")
            #expect("type".formattedPropertyName == "Type")
        }

        @Test("Handles multiple uppercase letters")
        func multipleUppercase() {
            #expect("myURLString".formattedPropertyName == "My U R L String")
            #expect("parseJSON".formattedPropertyName == "Parse J S O N")
        }

        @Test("Handles empty string")
        func emptyString() {
            #expect("".formattedPropertyName == "")
        }

        @Test("Handles already capitalized")
        func alreadyCapitalized() {
            #expect("Version".formattedPropertyName == "Version")
        }
    }

    // MARK: - ParsableArguments Introspection Tests

    @Suite("Argument Introspection")
    struct ArgumentIntrospectionTests {

        struct TestArgs: ParsableArguments {
            var name: String = "test"
            var count: Int = 42
            var verbose: Bool = false
            var dryRun: Bool = true
            var optional: String? = nil
            var optionalWithValue: String? = "present"
        }

        @Test("Introspects options correctly")
        func introspectOptions() {
            let args = TestArgs()
            let introspected = args.introspectArguments()

            let optionNames = introspected.options.map { $0.name }
            #expect(optionNames.contains("Name"))
            #expect(optionNames.contains("Count"))
            #expect(optionNames.contains("Optional With Value"))
        }

        @Test("Introspects flags correctly")
        func introspectFlags() {
            let args = TestArgs()
            let introspected = args.introspectArguments()

            let flagNames = introspected.flags.map { $0.name }
            #expect(flagNames.contains("Verbose"))
            #expect(flagNames.contains("Dry Run"))
        }

        @Test("Filters enabled flags correctly")
        func enabledFlags() {
            let args = TestArgs()
            let introspected = args.introspectArguments()

            let enabledNames = introspected.enabledFlags.map { $0.name }
            #expect(!enabledNames.contains("Verbose"))
            #expect(enabledNames.contains("Dry Run"))
        }

        @Test("Skips nil optional values")
        func skipsNilOptionals() {
            let args = TestArgs()
            let introspected = args.introspectArguments()

            let optionNames = introspected.options.map { $0.name }
            #expect(!optionNames.contains("Optional"))
            #expect(optionNames.contains("Optional With Value"))
        }

        @Test("Preserves option values")
        func preservesValues() {
            let args = TestArgs()
            let introspected = args.introspectArguments()

            let nameOption = introspected.options.first { $0.name == "Name" }
            #expect(nameOption?.value == "test")

            let countOption = introspected.options.first { $0.name == "Count" }
            #expect(countOption?.value == "42")
        }
    }
}
