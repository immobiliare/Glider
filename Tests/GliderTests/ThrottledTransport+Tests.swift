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

final class ThrottledTransportTests: XCTestCase, ThrottledTransportDelegate {
    
    var numberOfEvents = 100
    var bufferSize = 10
    
    var captureDelegateBlock: ((_ events: [ThrottledTransport.Payload], _ reason: ThrottledTransport.FlushReason) -> Void)?
    
    var emitTimer: Timer?
    
    /// The following test check if the buffer size flush is respected.
    func tests_throttledTransportBufferFlush() async throws {
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])
        format.structureFormatStyle = .object
        
        let transport = ThrottledTransport(bufferSize: bufferSize, flushInterval: 5, formatters: [format], delegate: self)
        
        let log = Log {
            $0.level = .debug
            $0.transports = [transport]
        }
                
        for i in 0..<numberOfEvents {
            log.info?.write(event: {
                $0.message = "test message \(i)!"
            })
        }
        
        var countBlocks = 0
        captureDelegateBlock = { events, reason in
            countBlocks += 1
        }
        
        XCTAssertTrue(countBlocks == 10)
    }
    
    /// Tests if transport flush interval set is respected.
    func tests_throttledTransportBufferTimeInterval() async throws {
        let exp = expectation(description: "end of sent")
        
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])

        let transport = ThrottledTransport(bufferSize: 100, flushInterval: 1, formatters: [format], delegate: self)

        let log = Log {
            $0.level = .debug
            $0.transports = [transport]
        }

        var sentMessages = 0
        var receivedMessages = 0
        let scheduledMessages = 10

        var receivedEventsBlock = [[Event]]()
        captureDelegateBlock = { events, reason in
            print("Captured \(events.count) events")
            receivedMessages += events.count
            receivedEventsBlock.append(events.map({ $0.0 }))
            
            if receivedMessages == scheduledMessages {
                self.emitTimer?.invalidate()
                self.emitTimer = nil
                exp.fulfill()
                return
            }
        }
                
        emitTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { _ in
            log.info?.write(event: {
                $0.message = "test message \(sentMessages)!"
            })
            
            sentMessages += 1
            if sentMessages == scheduledMessages {
                self.emitTimer?.invalidate()
            }
        })
        
        wait(for: [exp], timeout: 60)
        
        XCTAssertTrue(receivedMessages == scheduledMessages)
        XCTAssertTrue(receivedEventsBlock.count > 1)
        
        let allMessages = receivedEventsBlock.reduce([Event](), +)
        for i in 0..<allMessages.count {
            XCTAssertTrue(allMessages[i].message == "test message \(i)!")
        }
    }

    
    func record(_ transport: ThrottledTransport, events: [ThrottledTransport.Payload],
                reason: ThrottledTransport.FlushReason, _ completion: ThrottledTransport.Completion?) {
        captureDelegateBlock?(events, reason)
    }
    
}
