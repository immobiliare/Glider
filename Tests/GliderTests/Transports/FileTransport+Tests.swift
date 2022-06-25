//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created by Daniele Margutti
//  Email: <hello@danielemargutti.com>
//  Web: <http://www.danielemargutti.com>
//
//  Copyright ©2022 Daniele Margutti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

import XCTest
@testable import Glider

final class FileTransportTests: XCTestCase {
    
    /// The following test check if `FileLogTransport` transport layer.
    func test_fileLogTransport() async throws {
        let fileURL = URL.temporaryFileURL(fileName: nil, fileExtension: "log", removeIfExists: true)
        
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
            .delimiter(style: .repeat("-", 5)),
            .extra(keys: ["index"])
        ])
        format.structureFormatStyle = .object
        
        let fileTransport = try FileTransport(fileURL: fileURL) {
            $0.formatters = [format]
        }
        let log = Log {
            $0.level = .trace
            $0.transports = [fileTransport]
        }
        
        for i in 0..<100 {
            log.info?.write({
                $0.message = "test message \(i)!"
                $0.extra = ["index": "\(i)"]
            })
        }

        let writtenLogLines = try! String(contentsOfFile: fileURL.path).components(separatedBy: "\n").filter({
            $0.isEmpty == false
        })
        
        for i in 0..<writtenLogLines.count {
            if i < 10 {
                XCTAssertTrue(writtenLogLines[i] == "…message \(i)!-----extra={{\"index\":\"\(i)\"}}")
            } else {
                XCTAssertTrue(writtenLogLines[i] == "…essage \(i)!-----extra={{\"index\":\"\(i)\"}}")
            }
        }
    }
    
}

extension URL {
    
    static func temporaryFileURL(fileName: String? = nil, fileExtension: String? = nil, removeIfExists: Bool = true) -> URL {
        var fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(fileName ?? UUID().uuidString)
        
        if let fileExtension = fileExtension {
            fileURL = fileURL.appendingPathExtension(fileExtension)
        }
        
        if removeIfExists {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        return fileURL
    }
    
    static func newDirectoryURL(removeIfExists: Bool = true) throws -> URL? {
        let dirURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("logDirectory")
        
        var isDir = ObjCBool(false)
        if removeIfExists && FileManager.default.fileExists(atPath: dirURL.path, isDirectory: &isDir) && isDir.boolValue {
            try FileManager.default.removeItem(at: dirURL)
        }
        
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
        return dirURL
    }
    
}
