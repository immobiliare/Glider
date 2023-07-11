//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

import XCTest
@testable import Glider

@available(iOS 13.0.0, tvOS 13.0, *)
final class SQLiteTransportTests: XCTestCase, SQLiteTransportDelegate {
    
    var countWrittenPayloads: Int = 0
    var payloadsToWrite: Int = 0
    var maxEntries: Int = 0
    var exp: XCTestExpectation!

    func test_sqliteTransport() throws {
        exp = expectation(description: "SQLiteTransportTests")
                        
        self.maxEntries = 100
        self.countWrittenPayloads = 0
        self.payloadsToWrite = 110

        let sqliteTransport = try SQLiteTransport(databaseLocation: .inMemory, {
            $0.throttledTransport = .init({
                $0.maxEntries = self.maxEntries
                $0.autoFlushInterval = nil
            })
            $0.delegate = self
        })
        
        let log = Log {
            $0.level = .trace
            $0.transports = [sqliteTransport]
        }
                
        for i in 0..<payloadsToWrite {
            let level: Level = Level.allCases.randomElement() ?? .info

            log[level]?.write({
                $0.message = "test message \(i, privacy: .public)!"
                $0.tags = ["tag1": "value1", "tag2": "value2"]
                $0.extra = ["extrakey": "value"]
            })
        }
        
        wait(for: [exp], timeout: 60)
        
        // 10 remaining payloads pending in buffer
        let pendingPayloads = sqliteTransport.pendingPayloads
        
        XCTAssertEqual(countWrittenPayloads, maxEntries)
        XCTAssertEqual(pendingPayloads.count, (payloadsToWrite - maxEntries))
        
        sqliteTransport.flushPendingLogs()
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
        if countWrittenPayloads == maxEntries {
            // initial set
            exp?.fulfill()
        } else {
            // flushing buffer
            let remaining = (payloadsToWrite - maxEntries)
            if remaining != writtenPayloads.count {
                XCTFail()
            }
        }
    }
    
    func sqliteTransport(_ transport: SQLiteTransport, schemaMigratedFromVersion oldVersion: Int, toVersion newVersion: Int) {
        
    }
    
    func sqliteTransport(_ transport: SQLiteTransport, purgedLogs count: Int64) {
        
    }
    
}
