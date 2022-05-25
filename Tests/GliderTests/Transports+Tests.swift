//
//  File.swift
//  
//
//  Created by Daniele Margutti on 24/05/22.
//

import Foundation

import XCTest
@testable import Glider

final class TransportsTests: XCTestCase {
    
    /// The following test check if `FileLogTransport` transport layer.
    func test_fileLogTransport() {
        let fileURL = URL.newLogFileURL(removeContents: true)
        
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
            .delimiter(style: .repeat("-", 5)),
            .extra(keys: ["index"])
        ])
        
        let fileTransport = FileTransport(fileURL: fileURL, formatters: [format])!
        let log = Log {
            $0.level = .debug
            $0.transports = [fileTransport]
        }
        
        for i in 0..<100 {
            log.info?.write(event: {
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
    
    static func newLogFileURL(removeContents: Bool = true) -> URL {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test")
            .appendingPathExtension("log")
        
        if removeContents {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        return fileURL
    }
    
}
