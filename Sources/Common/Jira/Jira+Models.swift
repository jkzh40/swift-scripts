//
//  Jira+Models.swift
//  SwiftScripts
//

import Foundation

extension Jira {
    // MARK: - Endpoints

    public enum Endpoints: String {
        case myself = "/rest/api/3/myself"
        case searchJql = "/rest/api/3/search/jql"
        case searchApproximateCount = "/rest/api/3/search/approximate-count"
        case issue = "/rest/api/3/issue"
        case project = "/rest/api/3/project"
        case version = "/rest/api/3/version"

        public var path: String { rawValue }
    }

    // MARK: - Request Models

    struct SearchRequest: Codable {
        let fields: [String]?
        let jql: String
        let maxResults: Int?
        let nextPageToken: String?

        init(
            fields: [String]? = nil,
            jql: String,
            maxResults: Int? = nil,
            nextPageToken: String? = nil
        ) {
            self.fields = fields
            self.jql = jql
            self.maxResults = maxResults
            self.nextPageToken = nextPageToken
        }
    }

    public struct TransitionRequest: Codable {
        public let transition: TransitionID

        public struct TransitionID: Codable {
            public let id: String
        }
    }

    struct TransitionsResponse: Codable {
        let transitions: [Transition]
    }

    struct CountRequest: Codable {
        let jql: String
    }

    public struct CountResult: Codable {
        public let count: Int
    }

    // MARK: - Issue Update Models

    /// Request body for updating an issue
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-rest-api-3-issue-issueidorkey-put
    public struct IssueUpdateRequest: Codable {
        public let update: [String: [FieldOperation]]?
        public let fields: [String: AnyCodable]?

        public init(update: [String: [FieldOperation]]? = nil, fields: [String: AnyCodable]? = nil) {
            self.update = update
            self.fields = fields
        }
    }

    /// Operation for updating a field (add, set, remove)
    public struct FieldOperation: Codable {
        public let add: AnyCodable?
        public let set: AnyCodable?
        public let remove: AnyCodable?

        public init(add: AnyCodable? = nil, set: AnyCodable? = nil, remove: AnyCodable? = nil) {
            self.add = add
            self.set = set
            self.remove = remove
        }

        /// Add a value to a field
        public static func add(_ value: AnyCodable) -> FieldOperation {
            FieldOperation(add: value)
        }

        /// Set a field to a specific value (replaces existing)
        public static func set(_ value: AnyCodable) -> FieldOperation {
            FieldOperation(set: value)
        }

        /// Remove a value from a field
        public static func remove(_ value: AnyCodable) -> FieldOperation {
            FieldOperation(remove: value)
        }
    }

    /// Type-erased Codable wrapper for dynamic JSON values
    public struct AnyCodable: Codable {
        public let value: Any

        public init(_ value: Any) {
            self.value = value
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                value = string
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if let array = try? container.decode([AnyCodable].self) {
                value = array.map { $0.value }
            } else if let dict = try? container.decode([String: AnyCodable].self) {
                value = dict.mapValues { $0.value }
            } else {
                value = NSNull()
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch value {
            case let string as String:
                try container.encode(string)
            case let int as Int:
                try container.encode(int)
            case let bool as Bool:
                try container.encode(bool)
            case let array as [Any]:
                try container.encode(array.map { AnyCodable($0) })
            case let dict as [String: Any]:
                try container.encode(dict.mapValues { AnyCodable($0) })
            default:
                try container.encodeNil()
            }
        }
    }

    // MARK: - Response Models

    public struct User: Codable {
        public let accountId: String
        public let emailAddress: String?
        public let displayName: String
        public let active: Bool?
        public let timeZone: String?
        public let avatarUrls: [String: String]?
        public let `self`: String?

        public init(
            accountId: String,
            emailAddress: String? = nil,
            displayName: String,
            active: Bool? = true,
            timeZone: String? = nil,
            avatarUrls: [String: String]? = nil,
            self selfUrl: String? = nil
        ) {
            self.accountId = accountId
            self.emailAddress = emailAddress
            self.displayName = displayName
            self.active = active
            self.timeZone = timeZone
            self.avatarUrls = avatarUrls
            self.`self` = selfUrl
        }
    }

    public struct SearchResult: Codable {
        public let issues: [Issue]
        public let nextPageToken: String?

        /// Returns true if there are more results to fetch.
        /// The new API indicates more results by presence of nextPageToken.
        public var hasMore: Bool {
            nextPageToken != nil
        }
    }

    public struct Issue: Codable {
        public let id: String
        public let key: String
        public let fields: Fields?

        public var summary: String? { fields?.summary }
        public var status: Status? { fields?.status }
        public var assignee: User? { fields?.assignee }
        public var priority: Priority? { fields?.priority }
        public var fixVersions: [Version] { fields?.fixVersions ?? [] }

        public var url: String {
            "\(Jira.baseURL)/browse/\(key)"
        }

        public struct Fields: Codable {
            public let summary: String?
            public let status: Status?
            public let assignee: User?
            public let priority: Priority?
            public let fixVersions: [Version]?
            public let description: ADF?
            public let issuetype: IssueType?
            public let project: Project?
            public let created: String?
            public let updated: String?
            public let labels: [String]?
        }
    }

    public struct IssueType: Codable {
        public let id: String
        public let name: String
        public let description: String?
        public let subtask: Bool
    }

    public struct Status: Codable {
        public let id: String
        public let name: String
        public let description: String?
        public let statusCategory: StatusCategory?
    }

    public struct StatusCategory: Codable {
        public let id: Int
        public let key: String
        public let name: String
        public let colorName: String?
    }

    public struct Priority: Codable {
        public let id: String
        public let name: String
        public let iconUrl: String?
    }

    public struct Transition: Codable {
        public let id: String
        public let name: String
        public let to: Status?
    }

    public struct Project: Codable {
        public let id: String
        public let key: String
        public let name: String
        public let description: String?
        public let projectTypeKey: String?
        public let avatarUrls: [String: String]?
    }

    public struct Version: Codable {
        public let id: String?
        public let name: String
        public let description: String?
        public let archived: Bool?
        public let released: Bool?
        public let releaseDate: String?
        public let startDate: String?
        public let projectId: Int?

        public init(
            id: String? = nil,
            name: String,
            description: String? = nil,
            archived: Bool? = nil,
            released: Bool? = nil,
            releaseDate: String? = nil,
            startDate: String? = nil,
            projectId: Int? = nil
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.archived = archived
            self.released = released
            self.releaseDate = releaseDate
            self.startDate = startDate
            self.projectId = projectId
        }

        public struct CreateRequest: Codable {
            public let name: String
            public let description: String?
            public let projectId: Int
            public let startDate: String?
            public let releaseDate: String?
            public let archived: Bool?
            public let released: Bool?

            public init(
                name: String,
                description: String? = nil,
                projectId: Int,
                startDate: String? = nil,
                releaseDate: String? = nil,
                archived: Bool? = false,
                released: Bool? = false
            ) {
                self.name = name
                self.description = description
                self.projectId = projectId
                self.startDate = startDate
                self.releaseDate = releaseDate
                self.archived = archived
                self.released = released
            }
        }

        public struct UpdateRequest: Codable {
            public let name: String?
            public let description: String?
            public let archived: Bool?
            public let released: Bool?
            public let releaseDate: String?
            public let startDate: String?

            public init(
                name: String? = nil,
                description: String? = nil,
                archived: Bool? = nil,
                released: Bool? = nil,
                releaseDate: String? = nil,
                startDate: String? = nil
            ) {
                self.name = name
                self.description = description
                self.archived = archived
                self.released = released
                self.releaseDate = releaseDate
                self.startDate = startDate
            }
        }
    }

    // MARK: - Atlassian Document Format

    public struct ADF: Codable {
        public let type: String
        public let version: Int?
        public let content: [ADFContent]?
    }

    public struct ADFContent: Codable {
        public let type: String
        public let content: [ADFContent]?
        public let text: String?
        public let marks: [ADFMark]?
    }

    public struct ADFMark: Codable {
        public let type: String
        public let attrs: [String: String]?
    }
}

// MARK: - Date Formatter Extension

extension ISO8601DateFormatter {
    static let jiraDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
