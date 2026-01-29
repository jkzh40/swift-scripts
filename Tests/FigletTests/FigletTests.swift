import Testing

@testable import Figlet

@Suite("Figlet Tests")
struct FigletTests {

    // MARK: - Header Tests

    @Suite("Header Parsing")
    struct HeaderTests {
        @Test("Parses valid header line")
        func parseValidHeader() {
            let headerLine = "flf2a$ 6 5 20 15 3 0 143 229"
            let header = Figlet.FigletFile.Header.createFigletFontHeader(from: headerLine)

            #expect(header != nil)
            #expect(header?.hardBlank == "$")
            #expect(header?.height == 6)
            #expect(header?.baseline == 5)
            #expect(header?.maxLength == 20)
            #expect(header?.oldLayout == 15)
            #expect(header?.commentLines == 3)
            #expect(header?.commentDirection == .leftToRight)
            #expect(header?.fullLayout == 143)
            #expect(header?.codeTagCount == 229)
        }

        @Test("Parses header with different hard blank character")
        func parseHeaderWithDifferentHardBlank() {
            let headerLine = "flf2a# 8 6 16 0 4 0 0 0"
            let header = Figlet.FigletFile.Header.createFigletFontHeader(from: headerLine)

            #expect(header != nil)
            #expect(header?.hardBlank == "#")
            #expect(header?.height == 8)
        }

        @Test("Returns nil for invalid header")
        func parseInvalidHeader() {
            let invalidHeader = "not a valid header"
            let header = Figlet.FigletFile.Header.createFigletFontHeader(from: invalidHeader)

            #expect(header == nil)
        }

        @Test("Returns nil for empty string")
        func parseEmptyHeader() {
            let header = Figlet.FigletFile.Header.createFigletFontHeader(from: "")

            #expect(header == nil)
        }

        @Test("Parses right-to-left print direction")
        func parseRightToLeftDirection() {
            let headerLine = "flf2a$ 6 5 20 15 3 1 143 229"
            let header = Figlet.FigletFile.Header.createFigletFontHeader(from: headerLine)

            #expect(header?.commentDirection == .rightToLeft)
        }
    }

    // MARK: - FigletFile Tests

    @Suite("FigletFile Parsing")
    struct FigletFileTests {
        static let minimalFigletContent = """
            flf2a$ 2 2 4 0 1
            Comment line
             $@
            $@@
            # @
            #@@
            """

        @Test("Parses minimal figlet file content")
        func parseMinimalContent() {
            let file = Figlet.FigletFile.from(content: Self.minimalFigletContent)

            #expect(file != nil)
            #expect(file?.header.height == 2)
            #expect(file?.header.commentLines == 1)
            #expect(file?.headerLines.count == 2)  // header + 1 comment line
        }

        @Test("Extracts character lines correctly")
        func extractCharacterLines() {
            let file = Figlet.FigletFile.from(content: Self.minimalFigletContent)

            #expect(file != nil)
            #expect(file?.lines.isEmpty == false)
        }

        @Test("Detects character line terminator")
        func detectLineTerminator() {
            let file = Figlet.FigletFile.from(content: Self.minimalFigletContent)

            #expect(file?.characterLineTerminator() == "@")
        }

        @Test("Returns nil for invalid content")
        func parseInvalidContent() {
            let invalidContent = "This is not a figlet file"
            let file = Figlet.FigletFile.from(content: invalidContent)

            #expect(file == nil)
        }
    }

    // MARK: - Font Tests

    @Suite("Font Loading")
    struct FontTests {
        static let simpleFontContent = """
            flf2a$ 2 2 4 0 0
             $@
            $@@
            """

        @Test("Loads font from figlet file")
        func loadFontFromFile() {
            guard let file = Figlet.FigletFile.from(content: Self.simpleFontContent) else {
                Issue.record("Failed to parse figlet file")
                return
            }

            let font = Figlet.Font.from(file: file)

            #expect(font != nil)
            #expect(font?.height == 2)
        }

        @Test("Font contains space character")
        func fontContainsSpace() {
            guard let file = Figlet.FigletFile.from(content: Self.simpleFontContent) else {
                Issue.record("Failed to parse figlet file")
                return
            }

            let font = Figlet.Font.from(file: file)

            #expect(font?.characters[" "] != nil)
        }
    }

    // MARK: - Char Tests

    @Suite("Character Representation")
    struct CharTests {
        @Test("Creates character with correct height")
        func characterHeight() {
            let lines = ["###", "# #", "###"]
            let char = Figlet.Char(charLines: lines)

            #expect(char.height == 3)
            #expect(char.lines.count == 3)
        }

        @Test("Empty character has zero height")
        func emptyCharacter() {
            let char = Figlet.Char.EmptyChar

            #expect(char.height == 0)
            #expect(char.lines.isEmpty)
        }
    }

    // MARK: - FontName Tests

    @Suite("Font Selection")
    struct FontSelectionTests {
        @Test("FontName enum contains expected fonts")
        func fontNameCases() {
            let allFonts = Figlet.FontName.allCases
            #expect(allFonts.contains(.standard))
            #expect(allFonts.contains(.larry3d))
        }

        @Test("FontName raw values match file names")
        func fontNameRawValues() {
            #expect(Figlet.FontName.standard.rawValue == "standard")
            #expect(Figlet.FontName.larry3d.rawValue == "larry3d")
        }

        @Test("Render with standard font returns non-empty string")
        func renderWithStandardFont() {
            let result = Figlet.render("Hi", font: .standard)
            #expect(!result.isEmpty)
        }

        @Test("Render with larry3d font returns non-empty string")
        func renderWithLarry3dFont() {
            let result = Figlet.render("Hi", font: .larry3d)
            #expect(!result.isEmpty)
        }

        @Test("Different fonts produce different output")
        func differentFontsProduceDifferentOutput() {
            let standard = Figlet.render("A", font: .standard)
            let larry3d = Figlet.render("A", font: .larry3d)
            #expect(standard != larry3d)
        }

        @Test("Render defaults to standard font")
        func renderDefaultsToStandard() {
            let withDefault = Figlet.render("Hi")
            let withExplicit = Figlet.render("Hi", font: .standard)
            #expect(withDefault == withExplicit)
        }
    }

    // MARK: - Integration Tests

    @Suite("Integration")
    struct IntegrationTests {
        // A more complete font with multiple characters (space and !)
        static let completeFontContent = """
            flf2a$ 6 5 16 15 1 0 0 0
            Test font
                 $@
                 $@
                 $@
                 $@
                 $@
                 $@@
             $  @
            $$ $@
             $ $@
             $ $@
                $@
             $ $@@
            """

        @Test("Parses multi-character font")
        func parseMultiCharacterFont() {
            let file = Figlet.FigletFile.from(content: Self.completeFontContent)
            #expect(file != nil)

            if let file {
                let font = Figlet.Font.from(file: file)
                #expect(font != nil)
                #expect(font?.height == 6)
                // Should have space (ASCII 32) and ! (ASCII 33)
                #expect(font?.characters[" "] != nil)
                #expect(font?.characters["!"] != nil)
            }
        }

        @Test("Replaces hard blank with space in output")
        func replacesHardBlank() {
            let file = Figlet.FigletFile.from(content: Self.completeFontContent)

            if let file {
                let font = Figlet.Font.from(file: file)
                // The $ hard blank should be replaced with space in character lines
                if let exclamation = font?.characters["!"] {
                    for line in exclamation.lines {
                        #expect(!line.contains("$"))
                    }
                }
            }
        }
    }
}
