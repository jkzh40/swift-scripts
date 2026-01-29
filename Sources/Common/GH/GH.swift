//
//  GH.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

public enum GH {
    static let command = "gh"
    static let baseURL = "https://github.com"

    public static func checkAuth() async throws {
        let ghCheck = try await Platform.withStatus("Checking GitHub CLI installation...") {
            try await Process.run("which", args: ["gh"])
        }

        guard ghCheck.exitCode.isSuccess else {
            throw Errors.notInstalled
        }

        let authStatus = try await Platform.withStatus("Checking GitHub authentication...") {
            try await Process.run(command, args: ["auth", "status"])
        }

        guard authStatus.exitCode.isSuccess else {
            throw Errors.notAuthenticated
        }

        Platform.log("Successfully authenticated with GitHub.", color: .green)
    }

    public static func pullRequests(
        to branch: String? = nil,
        merged: Bool,
        maxCount: Int = 100
    ) async throws -> [PullRequest] {
        let result = try await Platform.withStatus("Fetching pull requests...") {
            try await Process.run(command) {
                "pr"
                "list"
                if merged {
                    "--state"
                    "merged"
                } else {
                    "--state"
                    "open"
                }
                "--json"
                "title,author,baseRefName,number,url,mergeCommit"
                "--limit"
                "\(maxCount)"
                if let branch {
                    "--base"
                    branch
                }
            }
        }

        guard result.exitCode.isSuccess else {
            throw Errors.commandFailed(command: "pr list", exitCode: result.exitCode, output: result.output)
        }

        guard let decoded = result.output.data(using: .utf8)?.jsonDecoded([PullRequest].self) else {
            throw Errors.decodingFailed(type: "PullRequest", output: result.output)
        }

        return decoded
    }

    public static func createRelease(
        version: String,
        branch: String,
        draft: Bool = true
    ) async throws -> String {
        let result = try await Platform.withStatus("Creating release \(version)...") {
            try await Process.run(command) {
                "release"
                "create"
                version
                "--target"
                branch
                "-t"
                "Release \(version)"
                if draft {
                    "--draft"
                }
                "--generate-notes"
                "-n"
                ""
            }
        }

        guard result.exitCode.isSuccess else {
            throw Errors.commandFailed(
                command: "release create \(version)", exitCode: result.exitCode, output: result.output)
        }

        guard let url = result.output.components(separatedBy: "\n").first(where: { $0.contains(baseURL) }) else {
            throw Errors.invalidResponse(message: "No release URL found in output for \(version)")
        }

        return url
    }

    public static func publishRelease(version: String) async throws {
        let result = try await Platform.withStatus("Publishing release \(version)...") {
            try await Process.run(
                command,
                args: ["release", "edit", version, "--draft=false"]
            )
        }

        guard result.exitCode.isSuccess else {
            throw Errors.commandFailed(
                command: "release edit \(version)", exitCode: result.exitCode, output: result.output)
        }
    }

    public static func uploadAsset(version: String, asset: URL) async throws {
        let result = try await Platform.withStatus("Uploading \(asset.lastPathComponent)...") {
            try await Process.run(
                command,
                args: ["release", "upload", version, asset.path]
            )
        }

        guard result.exitCode.isSuccess else {
            throw Errors.commandFailed(
                command: "release upload \(version)", exitCode: result.exitCode, output: result.output)
        }
    }
}
