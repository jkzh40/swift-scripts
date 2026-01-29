//
//  GH+Models.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

extension GH {
    public struct PullRequest: Codable {
        public let title: String
        public let author: Author
        public let baseRefName: String
        public let number: Int
        public let url: String
        public let mergeCommit: MergeCommit?

        public struct Author: Codable {
            public let id: String?
            public let is_bot: Bool
            public let login: String
            public let name: String?
        }

        public struct MergeCommit: Codable {
            public let oid: String
        }

        public var formatted: String {
            """
            PR #\(number) - \(title) | \(author.login) | \(url)
            """
        }

        public var formattedMarkdown: String {
            """
            [PR #\(number) - \(title) | \(author.login)](\(url))
            """
        }

        public var isAutomerge: Bool {
            let title = title.lowercased()
            return title.contains("auto-merge") || title.contains("automerge")
        }
    }
}
