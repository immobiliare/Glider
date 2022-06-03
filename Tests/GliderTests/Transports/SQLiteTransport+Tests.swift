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

final class SQLiteTransportTests: XCTestCase, SQLiteTransportDelegate {
    
    var countWrittenPayloads: Int = 0
    var payloadsToWrite: Int = 0
    var bufferSize: Int = 0
    var exp: XCTestExpectation!

    func test_sqliteTransport() async throws {
        exp = expectation(description: "SQLiteTransportTests")
        
        let dbURL = URL.temporaryFileURL()
                
        bufferSize = 100
        countWrittenPayloads = 0
        payloadsToWrite = 110

        let sqliteTransport = try  SQLiteTransport(location: .inMemory,
                                                   bufferSize: bufferSize,
                                                   flushInterval: nil,
                                                   delegate: self)

        
        let log = Log {
            $0.level = .debug
            $0.transports = [sqliteTransport]
        }
                
        for i in 0..<payloadsToWrite {
            let level: Level = Level.allCases.randomElement() ?? .info

            log[level]?.write(event: {
                $0.message = "test message \(i)!"
                $0.tags = ["tag1": "value1", "tag2": "value2"]
                $0.extra = ["extrakey": "value"]
            })
        }
        
        wait(for: [exp], timeout: 60)
        
        // 10 remaining payloads pending in buffer
        let pendingPayloads = sqliteTransport.pendingPayloads
        
        XCTAssertEqual(countWrittenPayloads, bufferSize)
        XCTAssertEqual(pendingPayloads.count, (payloadsToWrite - bufferSize))
        
        sqliteTransport.flush()
    }
    
    // MARK: - SQLiteTransportDelegate
    
    func sqliteTransport(_ transport: SQLiteTransport, openedDatabaseAtURL location: SQLiteDb.Location, isFileExist: Bool) {
        print("Database opened at: \(location.description)")
    }
    
    func sqliteTransport(_ transport: SQLiteTransport, didFailQueryWithError error: Error) {
        XCTFail("Failed to execute underlying query: \(error.localizedDescription)")
    }
    
    func sqliteTransport(_ transport: SQLiteTransport, writtenPayloads: [ThrottledTransport.Payload]) {
        countWrittenPayloads += writtenPayloads.count
        if countWrittenPayloads == bufferSize {
            // initial set
            exp?.fulfill()
        } else {
            // flushing buffer
            let remaining = (payloadsToWrite - bufferSize)
            if remaining != writtenPayloads.count {
                XCTFail()
            }
        }
    }
    
    func sqliteTransport(_ transport: SQLiteTransport, schemaMigratedFromVersion oldVersion: Int, toVersion newVersion: Int) {
        
    }
    
}
