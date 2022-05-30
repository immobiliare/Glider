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

final class SQLiteTransportTests: XCTestCase {
    
    func test_sqliteTransport() async throws {
        let dbURL = URL.temporaryFileName(fileName: "log", fileExtension: "sqlite", removeIfExists: true)
        
        let sqliteTransport = try  SQLiteTransport(location: .fileURL(dbURL), bufferSize: 100, flushInterval: nil)
        
        let log = Log {
            $0.level = .debug
            $0.transports = [sqliteTransport]
        }
                
        for i in 0..<100 {
            let level: Level = Level.allCases.randomElement() ?? .info

            log[level]?.write(event: {
                $0.message = "test message \(i)!"
            })
        }
        
    }
    
}
