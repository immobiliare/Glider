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
    
    func test_tableFormattersTests() async throws {
        let console = ConsoleTransport {
            $0.formatters = [TableFormatter(messageFields: [
                .timestamp(style: .iso8601),
                .delimiter(style: .spacedPipe),
                .message()
            ],
            tableFields: [
               // .subsystem(),
               // .level(style: .simple),
               // .callSite(),
               // .extra(keys: ["MixPanel", "Logged"])
                .customValue({ _ in
                    return ("Chiave", "Valore")
                })
            ])]
        }
        let log = Log {
            $0.subsystem = "Indomio.Network"
            $0.transports = [console]
            $0.level = .debug
        }
        
        log.info?.write({
            $0.message = "Just a simple text message"
            $0.extra = [
                "MixPanel": "enabled",
                "Logged": true,
                "AdSearch": "122"
            ]
        })
    }
    
}
