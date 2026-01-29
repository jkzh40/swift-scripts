//
//  Jira.swift
//  SwiftScripts
//

import Foundation

/// Jira REST API wrapper following the established patterns in this codebase.
/// Uses Atlassian Cloud REST API v3: https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/
public enum Jira {
    /// Base URL for Jira Cloud instance. Override via JIRA_BASE_URL environment variable.
    public static var baseURL: String {
        ProcessInfo.processInfo.environment["JIRA_BASE_URL"] ?? ""
    }

    @Secret(
        key: "JIRA_EMAIL",
        prompt: "Enter your Jira account email address."
    )
    static var email: String

    @Secret(
        key: "JIRA_API_TOKEN",
        prompt: "Create an API token at: https://id.atlassian.com/manage-profile/security/api-tokens"
    )
    static var apiToken: String

    /// Jira API credentials in format "email:api_token" for Basic auth
    static var credentials: String {
        "\(email):\(apiToken)"
    }

    // MARK: - Connectivity

    /// Check connectivity to Jira and validate credentials
    public static func checkConnectivity() async throws {
        let url = "\(baseURL)\(Endpoints.myself.path)"

        do {
            let output = try await Curl.get(
                endpoint: url,
                headers: [Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: "Checking Jira connectivity..."
            )

            if let user = output.data(using: .utf8)?.jsonDecoded(User.self) {
                Platform.log("Successfully connected to Jira as \(user.displayName).", color: .green)
            } else {
                Platform.log("Successfully connected to Jira.", color: .green)
            }
        } catch {
            throw Errors.notConnected(baseURL: baseURL, underlyingError: error.localizedDescription)
        }
    }

    // MARK: - Issues

    /// Search for issues using JQL
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/#api-rest-api-3-search-jql-post
    /// - Parameters:
    ///   - jql: JQL query string
    ///   - fields: Fields to return. Defaults to `["*all"]` for all fields. Use `["*navigable"]` for navigable fields only.
    ///   - maxResults: Maximum number of results per page (default 50, max 5000)
    ///   - nextPageToken: Token for fetching the next page of results
    ///   - withStatus: Status message to display during the request
    /// - Returns: Search result containing issues and pagination info
    public static func search(
        jql: String,
        fields: [String] = ["*all"],
        maxResults: Int = 50,
        nextPageToken: String? = nil
    ) async throws -> SearchResult {
        let url = "\(baseURL)\(Endpoints.searchJql.path)"
        let body = SearchRequest(
            fields: fields,
            jql: jql,
            maxResults: maxResults,
            nextPageToken: nextPageToken
        )

        let output = try await Curl.post(
            endpoint: url,
            body: body,
            headers: [Curl.jsonContentTypeHeader, Curl.acceptJsonHeader],
            credentials: credentials,
            maxTime: 60,
            withStatus: "Searching Jira issues..."
        )

        guard let decoded = output.data(using: .utf8)?.jsonDecoded(SearchResult.self) else {
            throw Errors.decodingFailed(type: "SearchResult", output: output)
        }

        return decoded
    }

    /// Get an approximate count of issues matching a JQL query
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/#api-rest-api-3-search-approximate-count-post
    public static func count(jql: String) async throws -> Int {
        let url = "\(baseURL)\(Endpoints.searchApproximateCount.path)"
        let body = CountRequest(jql: jql)

        let output = try await Curl.post(
            endpoint: url,
            body: body,
            headers: [Curl.jsonContentTypeHeader, Curl.acceptJsonHeader],
            credentials: credentials,
            withStatus: "Counting Jira issues..."
        )

        guard let decoded = output.data(using: .utf8)?.jsonDecoded(CountResult.self) else {
            throw Errors.decodingFailed(type: "CountResult", output: output)
        }

        return decoded.count
    }

    /// Get a single issue by key
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-rest-api-3-issue-issueidorkey-get
    /// - Parameters:
    ///   - issueKey: The issue key
    ///   - fields: Fields to return. Defaults to `["*all"]` for all fields.
    ///   - withStatus: Status message to display during the request
    /// - Returns: The issue if found, nil otherwise
    public static func getIssue(_ issueKey: String, fields: [String] = ["*all"]) async throws
        -> Issue?
    {
        let fieldsParam = fields.joined(separator: ",")
        let url = "\(baseURL)\(Endpoints.issue.path)/\(issueKey)?fields=\(fieldsParam)"

        do {
            let output = try await Curl.get(
                endpoint: url,
                headers: [Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: "Fetching issue \(issueKey)..."
            )
            return output.data(using: .utf8)?.jsonDecoded(Issue.self)
        } catch {
            Platform.log(
                "Failed to fetch issue \(issueKey): \(error.localizedDescription)", color: .yellow)
            return nil
        }
    }

    /// Update an issue
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-rest-api-3-issue-issueidorkey-put
    /// - Parameters:
    ///   - issueKey: The issue key
    ///   - request: The update request containing field operations
    ///   - withStatus: Status message to display during the request
    /// - Returns: True if the update succeeded
    @discardableResult
    public static func updateIssue(
        _ issueKey: String,
        request: IssueUpdateRequest,
        withStatus: String? = nil
    ) async throws -> Bool {
        let url = "\(baseURL)\(Endpoints.issue.path)/\(issueKey)"

        do {
            try await Curl.put(
                endpoint: url,
                body: request,
                headers: [Curl.jsonContentTypeHeader, Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: withStatus ?? "Updating issue \(issueKey)..."
            )
            return true
        } catch {
            Platform.log(
                "Failed to update issue \(issueKey): \(error.localizedDescription)", color: .yellow)
            return false
        }
    }

    /// Add a fix version to an issue
    /// - Parameters:
    ///   - issueKey: The issue key
    ///   - versionId: The version ID to add
    ///   - withStatus: Status message to display during the request
    /// - Returns: True if the update succeeded
    @discardableResult
    public static func addFixVersion(
        to issueKey: String,
        versionId: String,
        withStatus: String? = nil
    ) async throws -> Bool {
        let request = IssueUpdateRequest(
            update: ["fixVersions": [.add(AnyCodable(["id": versionId]))]]
        )
        return try await updateIssue(
            issueKey,
            request: request,
            withStatus: withStatus ?? "Adding fix version to \(issueKey)..."
        )
    }

    /// Add a fix version to an issue by version name
    /// - Parameters:
    ///   - issueKey: The issue key
    ///   - versionName: The version name to add
    ///   - withStatus: Status message to display during the request
    /// - Returns: True if the update succeeded
    @discardableResult
    public static func addFixVersion(
        to issueKey: String,
        versionName: String,
        withStatus: String? = nil
    ) async throws -> Bool {
        let request = IssueUpdateRequest(
            update: ["fixVersions": [.add(AnyCodable(["name": versionName]))]]
        )
        return try await updateIssue(
            issueKey,
            request: request,
            withStatus: withStatus ?? "Adding fix version '\(versionName)' to \(issueKey)..."
        )
    }

    /// Set fix versions on an issue (replaces existing)
    /// - Parameters:
    ///   - issueKey: The issue key
    ///   - versionIds: The version IDs to set
    ///   - withStatus: Status message to display during the request
    /// - Returns: True if the update succeeded
    @discardableResult
    public static func setFixVersions(
        on issueKey: String,
        versionIds: [String],
        withStatus: String? = nil
    ) async throws -> Bool {
        let versions = versionIds.map { ["id": $0] }
        let request = IssueUpdateRequest(
            update: ["fixVersions": [.set(AnyCodable(versions))]]
        )
        return try await updateIssue(
            issueKey,
            request: request,
            withStatus: withStatus ?? "Setting fix versions on \(issueKey)..."
        )
    }

    /// Remove a fix version from an issue
    /// - Parameters:
    ///   - issueKey: The issue key
    ///   - versionId: The version ID to remove
    ///   - withStatus: Status message to display during the request
    /// - Returns: True if the update succeeded
    @discardableResult
    public static func removeFixVersion(
        from issueKey: String,
        versionId: String,
        withStatus: String? = nil
    ) async throws -> Bool {
        let request = IssueUpdateRequest(
            update: ["fixVersions": [.remove(AnyCodable(["id": versionId]))]]
        )
        return try await updateIssue(
            issueKey,
            request: request,
            withStatus: withStatus ?? "Removing fix version from \(issueKey)..."
        )
    }

    /// Transition an issue to a new status
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-rest-api-3-issue-issueidorkey-transitions-post
    public static func transitionIssue(_ issueKey: String, to transitionId: String) async throws
        -> Bool
    {
        let url = "\(baseURL)\(Endpoints.issue.path)/\(issueKey)/transitions"
        let body = TransitionRequest(transition: .init(id: transitionId))

        do {
            try await Curl.post(
                endpoint: url,
                body: body,
                headers: [Curl.jsonContentTypeHeader, Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: "Transitioning issue \(issueKey)..."
            )
            return true
        } catch {
            Platform.log(
                "Failed to transition issue \(issueKey): \(error.localizedDescription)", color: .yellow)
            return false
        }
    }

    /// Get available transitions for an issue
    public static func getTransitions(for issueKey: String) async throws -> [Transition] {
        let url = "\(baseURL)\(Endpoints.issue.path)/\(issueKey)/transitions"

        do {
            let output = try await Curl.get(
                endpoint: url,
                headers: [Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: "Getting transitions for issue \(issueKey)..."
            )
            return output.data(using: .utf8)?.jsonDecoded(TransitionsResponse.self)?.transitions ?? []
        } catch {
            return []
        }
    }

    // MARK: - Projects

    /// Get project by key
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-projects/#api-rest-api-3-project-projectidorkey-get
    public static func getProject(_ projectKey: String) async throws -> Project? {
        let url = "\(baseURL)\(Endpoints.project.path)/\(projectKey)"

        do {
            let output = try await Curl.get(
                endpoint: url,
                headers: [Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: "Fetching project \(projectKey)..."
            )
            return output.data(using: .utf8)?.jsonDecoded(Project.self)
        } catch {
            Platform.log(
                "Failed to fetch project \(projectKey): \(error.localizedDescription)", color: .yellow)
            return nil
        }
    }

    // MARK: - Versions

    /// Get all versions for a project
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-project-versions/#api-rest-api-3-project-projectidorkey-versions-get
    public static func getVersions(
        for projectKey: String
    ) async throws -> [Version] {
        let url = "\(baseURL)\(Endpoints.project.path)/\(projectKey)/versions"

        do {
            let output = try await Curl.get(
                endpoint: url,
                headers: [Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: "Fetching versions for \(projectKey)..."
            )
            return output.data(using: .utf8)?.jsonDecoded([Version].self) ?? []
        } catch {
            Platform.log("Failed to fetch versions: \(error.localizedDescription)", color: .yellow)
            return []
        }
    }

    /// Create a new version in a project
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-project-versions/#api-rest-api-3-version-post
    public static func createVersion(
        _ request: Version.CreateRequest
    ) async throws -> Version? {
        let url = "\(baseURL)\(Endpoints.version.path)"

        do {
            let output = try await Curl.post(
                endpoint: url,
                body: request,
                headers: [Curl.jsonContentTypeHeader, Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: "Creating version \(request.name)..."
            )
            return output.data(using: .utf8)?.jsonDecoded(Version.self)
        } catch {
            Platform.log("Failed to create version: \(error.localizedDescription)", color: .red)
            return nil
        }
    }

    /// Update an existing version
    /// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-project-versions/#api-rest-api-3-version-id-put
    public static func updateVersion(
        id: String,
        _ request: Version.UpdateRequest
    ) async throws -> Version? {
        let url = "\(baseURL)\(Endpoints.version.path)/\(id)"

        do {
            let output = try await Curl.put(
                endpoint: url,
                body: request,
                headers: [Curl.jsonContentTypeHeader, Curl.acceptJsonHeader],
                credentials: credentials,
                withStatus: "Updating version..."
            )
            return output.data(using: .utf8)?.jsonDecoded(Version.self)
        } catch {
            Platform.log("Failed to update version: \(error.localizedDescription)", color: .red)
            return nil
        }
    }

    /// Release a version (mark as released with release date)
    public static func releaseVersion(id: String, releaseDate: String? = nil) async throws -> Version? {
        let date = releaseDate ?? ISO8601DateFormatter.jiraDateFormatter.string(from: Date())
        let request = Version.UpdateRequest(released: true, releaseDate: date)
        return try await updateVersion(id: id, request)
    }

    /// Find a version by name in a project
    public static func findVersion(named name: String, in projectKey: String) async throws -> Version? {
        let versions = try await getVersions(for: projectKey)
        return versions.first { $0.name == name }
    }
}
