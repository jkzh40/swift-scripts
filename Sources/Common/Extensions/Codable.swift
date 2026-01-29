//
//  Codable.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/12/26.
//

import Foundation

extension Encodable {
    public func jsonEncoded() -> Data? {
        try? JSONEncoder().encode(self)
    }
}

extension Data {
    public func utf8String() -> String? {
        String(data: self, encoding: .utf8)
    }

    public func jsonDecoded<T: Decodable>(_ type: T.Type = T.self) -> T? {
        try? JSONDecoder().decode(T.self, from: self)
    }
}
