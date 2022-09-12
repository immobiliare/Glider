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
@testable import GliderSwiftLog
import Logging

final class GliderSwiftLogTests: XCTestCase {
    
    func test_gliderAsSwiftLogBackend() throws {
        // Setup some scope's extra and tags
        GliderSDK.shared.scope.extra = [
            "global_extra": "global"
        ]
        
        GliderSDK.shared.scope.tags = [
            "tags_scope": "val_tag"
        ]
        
        
        // Create glider setup
        let testTransport = TestTransport { event in
            // Validate the filtering.
            if event.level == .trace {
                XCTAssertEqual(event.message.description, "TRACE message")
            } else if event.level == .debug {
                XCTAssertEqual(event.message.description, "DEBUG message")
                XCTAssertTrue(event.allExtra?.values["extra_2"] as? String == "v1")
                XCTAssertTrue(event.allExtra?.values["global_extra"] as? String == "global")
            } else {
                XCTAssertEqual(event.message.description, "ERROR message")
                XCTAssertTrue(event.allExtra?.values["global_extra"] as? String == "local")
            }
            XCTAssertTrue(event.tags?["logger"] as? String == "swiftlog")
        }
        
        let gliderLog = Log {
            $0.level = .trace
            $0.transports = [
                testTransport
            ]
        }
        
        // Setup Glider as backend for swift-log.
        LoggingSystem.bootstrap {
            var handler = GliderSwiftLogHandler(label: $0, logger: gliderLog)
            handler.logLevel = .trace
            return handler
        }
        
        // Create swift-log instance.
        let swiftLog = Logger(label: "com.example.yourapp.swiftlog")
        swiftLog.trace("TRACE message", metadata: ["extra_1" : "v1"])  // Will be ignored.
        swiftLog.debug("DEBUG message", metadata: ["extra_2" : "v1"])  // Will be logged.
        swiftLog.error("ERROR message", metadata: ["global_extra" : "local"])  // Will be logged.
    }
    
}

// MARK: - Private Utilities

fileprivate class TestTransport: Transport {
    typealias OnReceiveEvent = ((Event) -> Void)

    private var onReceiveEvent: OnReceiveEvent?
    
    /// Transport is enabled.
    public var isEnabled: Bool = true
    
    /// Minumum accepted level for this transport.
    /// `nil` means every passing message level is accepted.
    public var minimumAcceptedLevel: Level? = nil
    
    init(onReceiveEvent: @escaping OnReceiveEvent) {
        self.onReceiveEvent = onReceiveEvent
    }
    
    func record(event: Event) -> Bool {
        onReceiveEvent?(event)
        return true
    }
    
    var queue: DispatchQueue = DispatchQueue(label: String(describing: type(of: TestTransport.self)), attributes: [])
    
}
