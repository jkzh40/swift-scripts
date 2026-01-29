//
//  Curl+Models.swift
//  SwiftScripts
//
//  Created by Jack Zhao on 1/13/26.
//

import Foundation

extension Curl {
    public enum MimeType: String {
        case json = "application/json"
        case xml = "application/xml"
        case zip = "application/zip"
        case html = "text/html"
        case plain = "text/plain"
        case pdf = "application/pdf"
        case jpeg = "image/jpeg"
        case png = "image/png"
    }
}
