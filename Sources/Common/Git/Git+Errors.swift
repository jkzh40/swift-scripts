//
//  Git+Errors.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

extension Git {
    public enum Errors: Error, LocalizedError {
        case failed(command: String, exitCode: Int32, output: String)
        case notARepository

        public var errorDescription: String? {
            switch self {
            case .failed(let cmd, let code, let output):
                "Git command '\(cmd)' failed with exit code \(code): \(output)"
            case .notARepository:
                "Not a git repository"
            }
        }
    }
}
