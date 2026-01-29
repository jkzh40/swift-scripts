//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===--------------------------------------------------------------------

import Foundation

public enum Figlet {
    /// Available bundled fonts
    public enum FontName: String, CaseIterable {
        case standard
        case larry3d
    }

    /// Render text to a string using the specified font
    public static func render(_ text: String, boxed: Bool = false, font fontName: FontName = .standard) -> String {
        let font = loadFont(fontName)
        var lines: [String] = []

        for lineIndex in 0..<font.height {
            var line = ""
            for c in text {
                if let fontCharacter = font.characters[c], lineIndex < fontCharacter.lines.count {
                    line += fontCharacter.lines[lineIndex]
                }
            }
            lines.append(line)
        }

        let rendered = lines.joined(separator: "\n")
        return boxed ? Self.boxed(rendered) : rendered
    }

    /// Wrap text in a decorative Unicode box.
    /// - Parameter text: The text to wrap
    /// - Returns: The text wrapped in a box with ╔═╗║╚═╝ characters
    public static func boxed(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let maxWidth = lines.map { $0.count }.max() ?? 0
        let boxWidth = maxWidth + 4  // 2 chars padding on each side

        let top = "╔" + String(repeating: "═", count: boxWidth) + "╗"
        let bottom = "╚" + String(repeating: "═", count: boxWidth) + "╝"
        let emptyLine = "║" + String(repeating: " ", count: boxWidth) + "║"

        var result = [top, emptyLine]

        for line in lines {
            let padding = maxWidth - line.count
            let paddedLine = "║  " + line + String(repeating: " ", count: padding + 2) + "║"
            result.append(paddedLine)
        }

        result.append(emptyLine)
        result.append(bottom)

        return result.joined(separator: "\n")
    }

    /// Load a bundled font by name
    private static func loadFont(_ name: FontName) -> Font {
        guard let url = Bundle.module.url(forResource: name.rawValue, withExtension: "flf") else {
            fatalError("invalid figlet font file: missing resource '\(name.rawValue).flf'")
        }
        guard let figletFile = FigletFile.from(url: url) else {
            fatalError("invalid figlet font file: invalid file '\(name.rawValue).flf'")
        }
        guard let font = Font.from(file: figletFile) else {
            fatalError("invalid figlet font file: invalid font '\(name.rawValue).flf'")
        }
        return font
    }
}
