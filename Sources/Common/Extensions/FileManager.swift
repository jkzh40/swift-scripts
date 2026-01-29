//
//  FileManager.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

extension FileManager {
    /// Returns the current working directory as a URL
    public var pwd: URL {
        URL(fileURLWithPath: currentDirectoryPath)
    }

    /// Lists contents of a directory
    public func ls(_ path: String) throws -> [String] {
        try contentsOfDirectory(atPath: path)
    }

    /// Lists contents of a directory URL
    public func ls(_ url: URL) throws -> [String] {
        try contentsOfDirectory(atPath: url.path)
    }

    /// Lists contents of a directory as URLs
    public func ls(_ url: URL, fullPaths: Bool) throws -> [URL] {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }

    /// Creates a directory at the specified path
    public func mkdir(_ path: String, withIntermediateDirectories: Bool = true) throws {
        try createDirectory(atPath: path, withIntermediateDirectories: withIntermediateDirectories)
    }

    /// Creates a directory at the specified URL
    public func mkdir(_ url: URL, withIntermediateDirectories: Bool = true) throws {
        try createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
}
