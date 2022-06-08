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
import CloudKit

class WebSocketTransportTests: XCTestCase {
    
    func tests_webSocketTransport() async throws {
        let exp = expectation(description: "tests_throttledTransportBufferFlush")
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])
        format.structureFormatStyle = .object
    
        
        let transport = try WebSocketTransport(url: "wss://socketsbay.com/wss/v2/2/demo/") {
            $0.connectAutomatically = true
            $0.formatters = [format]
        }
                
        let log = Log {
            $0.level = .debug
            $0.transports = [transport]
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            log.info?.write("ciao")
        })
                
        wait(for: [exp], timeout: 500)
        
    }
}
