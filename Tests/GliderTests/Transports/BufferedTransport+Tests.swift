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

final class BufferedTransportTests: XCTestCase {
    
    func tests_bufferedTransport() async throws {        
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
            .delimiter(style: .repeat("-", 5)),
            .extra(keys: ["index"])
        ])
        format.structureFormatStyle = .object
        
        let bufferLimit = 5
        let bufferedTransport: BufferedTransport<BItem> = .init(bufferLimit: bufferLimit, formatters: [format]) { event, data in
            BItem(event: event, message: data)
        }
        
        let log = Log {
            $0.level = .debug
            $0.transports = [bufferedTransport]
        }
        
        for i in 0..<(bufferLimit * 3) {
            log.info?.write(event: {
                $0.message = "test message \(i)!"
                $0.extra = ["index": "\(i)"]
            })
        }
        
        XCTAssertTrue(bufferedTransport.buffer.count == bufferLimit)
        XCTAssertNotNil(bufferedTransport.buffer.first)
        XCTAssertTrue(bufferedTransport.buffer.first?.event.message == "test message \(10)!")
    }
    
}

/// A dummy struct.
struct BItem {
    var event: Event
    var message: String?
    
    public init(event: Event, message: SerializableData) {
        self.event = event
        self.message = message.asString()
    }
}
