//
//  Git+Models.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

extension Git {
    public struct Commit: Codable {
        static let delimiter = "|"
        public let hash: String
        public let date: String
        public let time: String
        public let author: String
        public let message: String

        public init?(raw: String) {
            let components = raw.split(separator: Commit.delimiter).map(String.init)
            guard components.count == 5 else { return nil }
            self.hash = components[0]
            self.date = components[1]
            self.time = components[2]
            self.author = components[3]
            self.message = components[4]
        }

        public init(hash: String, date: String, time: String, author: String, message: String) {
            self.hash = hash
            self.date = date
            self.time = time
            self.author = author
            self.message = message
        }

        public var shortHash: String {
            String(hash.prefix(7))
        }

        public var formatted: String {
            "\(shortHash) | \(author) | \(dateTime) | \(message)"
        }

        public var formattedMarkdown: String {
            "- `\(shortHash)` | \(author) | \(dateTime) | \(message)"
        }

        public var dateTime: String {
            "\(date) \(time)"
        }
    }
}
