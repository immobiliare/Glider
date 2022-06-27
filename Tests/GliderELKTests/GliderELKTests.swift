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

import XCTest
@testable import Glider
@testable import GliderELK
import NIO
import NIOConcurrencyHelpers

final class GliderELKTests: XCTestCase, GliderELKTransportDelegate {
    
    func test_gliderTests() async throws {
        let exp = expectation(description: "test")
        let transport = try GliderELKTransport(hostname: "127.0.0.1", port: 5000, delegate: self) {
            $0.uploadInterval = TimeAmount.seconds(4)
        }
        
        let log = Log {
            $0.level = .info
            $0.transports = [transport]
        }
        
        log.info?.write(msg: "TESTTTTT", extra: ["mykey": "myvalue"])
        
        wait(for: [exp], timeout: 70)
    }
    
    // MARK: - GliderELKTransportDelegate
    
    func elkTransport(_ transport: GliderELKTransport, didFailSendingEvent event: Event, error: Error) {
        
    }

}
