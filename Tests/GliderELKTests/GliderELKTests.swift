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

import XCTest
@testable import Glider
@testable import GliderELK
import NIO
import NIOConcurrencyHelpers

final class GliderELKTests: XCTestCase, GliderELKTransportDelegate {
    /*
    /// You can use <https://github.com/deviantony/docker-elk> to test the implementation.
    func test_elkTest() async throws {
        let exp = expectation(description: "test")
        let transport = try GliderELKTransport(hostname: "127.0.0.1", port: 5000, delegate: self) {
            $0.uploadInterval = TimeAmount.seconds(10)
        }
        
        let log = Log {
            $0.subsystem = "com.myapp"
            $0.category = "network"
            $0.level = .info
            $0.transports = [transport]
        }
        
        for i in 0..<10 {
            print("Sending message \(i)...")
            log.info?.write(msg: "NEW \(i)", extra: ["key": "\(i)"])
        }
        
        wait(for: [exp], timeout: 70)
    }
    */
    // MARK: - GliderELKTransportDelegate
    
    func elkTransport(_ transport: GliderELKTransport, didFailSendingEvent event: Event, error: Error) {
        XCTFail("Failed to send event: \(event.message.content) {error=\(error.localizedDescription)}")
    }
    
}
