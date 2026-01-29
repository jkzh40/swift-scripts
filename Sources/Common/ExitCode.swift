//
//  ExitCode.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/12/26.
//

import Foundation

public enum ExitCode: Int32 {
    case success = 0
    case failure = 1
}

extension Int32 {
    public var isSuccess: Bool { self == ExitCode.success.rawValue }
    public var isFailure: Bool { self == ExitCode.failure.rawValue }
}
