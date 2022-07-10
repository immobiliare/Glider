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

final class TableFormattersTest: XCTestCase {

    /// The following test check if the `TableFormatter` return valid values
    /// when printed to the console.
    func test_tableFormattersTests() async throws {
        let tableFormatter = TableFormatter(
            messageFields: [
                .timestamp(style: .iso8601),
                .delimiter(style: .spacedPipe),
                .message()
            ],
            tableFields: [
                .subsystem(),
                .level(style: .simple),
                .callSite(),
                .extra(keys: ["AdSearch", "MagicNumber"]),
                .customValue({ event in
                    return ("MyKey", event?.id ?? "-")
            })
        ])
        
        let consoleTransport = ConsoleTransport {
            $0.formatters = [tableFormatter]
        }
        
        let testTransport = TestTransport { event in
            let msg = tableFormatter.format(event: event)!.asString()!
            print(msg)
            
            XCTAssertTrue(msg.contains("| Just a simple text message\n"))

            XCTAssertTrue(msg.contains("""
            ┌─────────────┬──────────────────────────────────────┐
            │ ID          │ VALUE                                │
            ├─────────────┼──────────────────────────────────────┤
            │ Subsystem   │ MyApp.Network                        │
            │ Level       │ info
            """))
            
            XCTAssertTrue(msg.contains("""
            │ AdSearch    │ 122                                  │
            │ MagicNumber │ enabled                              │
            """))
            
            XCTAssertTrue(msg.contains("""
            └─────────────┴──────────────────────────────────────┘
            """))
            
        }
        
        let log = Log {
            $0.subsystem = "MyApp.Network"
            $0.category = "NetworkingService"
            $0.transports = [consoleTransport, testTransport]
            $0.level = .trace
        }
        
        log.info?.write({
            $0.message = "Just a simple text message"
            $0.extra = [
                "MagicNumber": "enabled",
                "Logged": true,
                "AdSearch": "122"
            ]
        })
    }
    
}
