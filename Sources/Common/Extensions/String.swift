//
//  String.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/12/26.
//

import Foundation

extension String {
    public static var newLine: String { "\n" }

    public var separatedByNewLines: [String] {
        components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    public func mappedLines(_ transform: (String) -> String) -> Self {
        separatedByNewLines.map(transform).joined(separator: .newLine)
    }

    /// Checks if the string is a valid semantic version (e.g., "1.0.0", "2.1.3-alpha+12345").
    public var isValidSemanticVersion: Bool {
        let pattern = #"^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}

extension String {
    public func append(to file: URL, encoding: String.Encoding = .utf8) throws {
        guard let data = data(using: encoding) else { return }
        if let handle = try? FileHandle(forWritingTo: file) {
            handle.seekToEndOfFile()
            handle.write(data)
            try handle.close()
        }
    }
}

extension [String] {
    public var joinedWithNewLines: String {
        joined(separator: .newLine)
    }
}
