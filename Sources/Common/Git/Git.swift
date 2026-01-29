//
//  Git.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

public enum Git {
    static let command = "git"

    public static func remote(_ name: String = "origin") async throws -> String {
        let result = try await Process.run(command, args: ["remote", "get-url", name])
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "remote get-url", exitCode: result.exitCode, output: result.output)
        }
        return result.output
    }

    public static func remotes() async throws -> [String] {
        let result = try await Process.run(command, args: ["remote"])
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "remote", exitCode: result.exitCode, output: result.output)
        }
        return result.output.separatedByNewLines
    }

    public static func currentBranch() async throws -> String {
        let result = try await Process.run(command, args: ["rev-parse", "--abbrev-ref", "HEAD"])
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "rev-parse", exitCode: result.exitCode, output: result.output)
        }
        return result.output
    }

    public static func isRepository() async -> Bool {
        let result = try? await Process.run(command, args: ["rev-parse", "--git-dir"])
        return result?.exitCode.isSuccess ?? false
    }

    public static func fetch(remote: String = "origin", prune: Bool = false) async throws {
        try await Platform.withStatus("Fetching changes") {
            let result = try await Process.run(command) {
                "fetch"
                remote
                if prune { "--prune" }
            }
            guard result.exitCode.isSuccess else {
                throw Errors.failed(command: "fetch", exitCode: result.exitCode, output: result.output)
            }
        }
    }

    public static func pull(remote: String = "origin", branch: String? = nil, rebase: Bool = false) async throws {
        try await Platform.withStatus("Pulling changes") {
            let result = try await Process.run(command) {
                "pull"
                if rebase { "--rebase" }
                remote
                if let branch { branch }
            }
            guard result.exitCode.isSuccess else {
                throw Errors.failed(command: "pull", exitCode: result.exitCode, output: result.output)
            }
        }
    }

    public static func checkout(_ ref: String, create: Bool = false) async throws {
        let result = try await Platform.withStatus("Checking out \(ref)") {
            try await Process.run(command) {
                "checkout"
                if create { "-b" }
                ref
            }
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "checkout", exitCode: result.exitCode, output: result.output)
        }
    }

    public static func branches(remote: Bool = false, all: Bool = false) async throws -> [String] {
        let result = try await Process.run(command) {
            "branch"
            if all { "-a" } else if remote { "-r" }
            "--format=%(refname:short)"
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "branch", exitCode: result.exitCode, output: result.output)
        }
        return result.output.separatedByNewLines
    }

    public static func status(short: Bool = true) async throws -> String {
        let result = try await Process.run(command) {
            "status"
            if short { "--short" }
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "status", exitCode: result.exitCode, output: result.output)
        }
        return result.output
    }

    public static func isDirty() async throws -> Bool {
        let status = try await status(short: true)
        return !status.isEmpty
    }

    public static func diff(staged: Bool = false, file: String? = nil) async throws -> String {
        let result = try await Process.run(command) {
            "diff"
            if staged { "--staged" }
            if let file { file }
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "diff", exitCode: result.exitCode, output: result.output)
        }
        return result.output
    }

    public static func stash(message: String? = nil, includeUntracked: Bool = false) async throws {
        let result = try await Process.run(command) {
            "stash"
            "push"
            if includeUntracked { "--include-untracked" }
            if let message {
                "-m"
                message
            }
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "stash push", exitCode: result.exitCode, output: result.output)
        }
    }

    public static func stashPop() async throws {
        let result = try await Process.run(command, args: ["stash", "pop"])
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "stash pop", exitCode: result.exitCode, output: result.output)
        }
    }

    public static func stashList() async throws -> [String] {
        let result = try await Process.run(command, args: ["stash", "list"])
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "stash list", exitCode: result.exitCode, output: result.output)
        }
        return result.output.separatedByNewLines
    }

    public static func commits(
        on branch: String? = nil,
        remote: String = "origin",
        from start: String? = nil,
        to end: String? = nil,
        merges: Bool = false,
        firstParent: Bool = false,
        maxCount: Int = 100
    ) async throws -> [Commit] {
        let result = try await Process.run(command) {
            "--no-pager"
            "log"
            "--max-count=\(maxCount)"
            if let start, let end {
                "\(start)..\(end)"
            }
            if merges {
                "--merges"
            }
            if firstParent {
                "--first-parent"
            }
            "--pretty=format:%H\(Commit.delimiter)%ad\(Commit.delimiter)%an\(Commit.delimiter)%s"
            "--date=format:%Y-%m-%d\(Commit.delimiter)%H:%M"
            if let branch {
                "\(remote)/\(branch)"
            }
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "log", exitCode: result.exitCode, output: result.output)
        }
        return result.output.separatedByNewLines.compactMap { Commit(raw: $0) }
    }

    public static func commit(for tag: String) async throws -> Commit? {
        let result = try await Process.run(command) {
            "--no-pager"
            "log"
            "-n"
            "1"
            "--pretty=format:%H\(Commit.delimiter)%ad\(Commit.delimiter)%an\(Commit.delimiter)%s"
            "--date=format:%Y-%m-%d\(Commit.delimiter)%H:%M"
            tag
        }
        return result.exitCode.isSuccess ? Commit(raw: result.output) : nil
    }

    public static func tags(on branch: String? = nil, remote: String = "origin") async throws -> [String] {
        let result = try await Process.run(command) {
            "tag"
            "--sort=-creatordate"
            if let branch {
                "--merged"
                "\(remote)/\(branch)"
            }
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "tag", exitCode: result.exitCode, output: result.output)
        }
        return result.output.separatedByNewLines
    }

    public static func createTag(_ name: String, message: String? = nil, ref: String? = nil) async throws {
        let result = try await Process.run(command) {
            "tag"
            if let message {
                "-a"
                name
                "-m"
                message
            } else {
                name
            }
            if let ref { ref }
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "tag", exitCode: result.exitCode, output: result.output)
        }
    }

    public static func pushTag(_ name: String, remote: String = "origin") async throws {
        let result = try await Platform.withStatus("Pushing tag \(name)") {
            try await Process.run(command, args: ["push", remote, name])
        }
        guard result.exitCode.isSuccess else {
            throw Errors.failed(command: "push tag", exitCode: result.exitCode, output: result.output)
        }
    }

    /// Checks if `ancestor` is an ancestor of `descendant`
    public static func isAncestor(_ ancestor: String, of descendant: String) async -> Bool {
        let result = try? await Process.run(command, args: ["merge-base", "--is-ancestor", ancestor, descendant])
        return result?.exitCode.isSuccess ?? false
    }
}
