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

class ThrottledTransportTests: XCTestCase, ThrottledTransportDelegate {
    
    var numberOfEvents = 100
    var bufferSize = 10
    
    var captureDelegateBlock: ((_ events: [ThrottledTransport.Payload], _ reason: ThrottledTransport.FlushReason) -> Void)?
    
    var emitTimer: Timer?
    
    func record(_ transport: ThrottledTransport, events: [ThrottledTransport.Payload],
                reason: ThrottledTransport.FlushReason, _ completion: ThrottledTransport.Completion?) {
        captureDelegateBlock?(events, reason)
    }
    
    /// The following test check if the buffer size flush is respected.
    func tests_throttledTransportBufferFlush() async throws {
        let exp = expectation(description: "tests_throttledTransportBufferFlush")
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])
        format.structureFormatStyle = .object
        
        var countBlocks = 0
        captureDelegateBlock = { events, reason in
            countBlocks += 1
            
            if countBlocks == 10 {
                exp.fulfill()
            }
        }
        
        let transport = ThrottledTransport {
            $0.bufferSize = bufferSize
            $0.flushInterval = 5
            $0.formatters = [format]
            $0.delegate = self
        }
                
        let log = Log {
            $0.level = .debug
            $0.transports = [transport]
        }
                
        for i in 0..<numberOfEvents {
            log.info?.write(event: {
                $0.message = "test message \(i)!"
            })
        }
        
        wait(for: [exp], timeout: 80)
    }

    /// Tests if transport flush interval set is respected.
    func tests_throttledTransportBufferTimeInterval() async throws {
        let exp = expectation(description: "end of sent")
        
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])

        let transport = ThrottledTransport {
            $0.bufferSize = 100
            $0.flushInterval = 1
            $0.formatters = [format]
            $0.delegate = self
        }

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

    func test_throttledManualFlusj() async throws {
        let exp = expectation(description: "end of sent")
        
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])

        let transport = ThrottledTransport {
            $0.bufferSize = 100
            $0.flushInterval = 5
            $0.formatters = [format]
            $0.delegate = self
        }

        let log = Log {
            $0.level = .debug
            $0.transports = [transport]
        }
        
        var totalEvents = [Event]()

        captureDelegateBlock = { events, reason in
            if totalEvents.isEmpty {
                XCTAssertTrue(events.count == 99)
            } else {
                XCTAssertTrue(events.count == 1)
            }
            
            for event in events {
                totalEvents.append(event.0)
            }
            
            print("Captured \(events.count) events via flush \(reason.rawValue) (total=\(totalEvents.count))")
            
            if totalEvents.count == 100 {
                exp.fulfill()
            }
        }
        
        for i in 0..<99 {
            log.info?.write(event: {
                $0.message = "test message \(i)!"
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            transport.flush()
            
            log.info?.write(event: {
                $0.message = "final"
            })
        }
        
        wait(for: [exp], timeout: 60)
        
        XCTAssertTrue(totalEvents.count == 100)
        XCTAssertTrue(totalEvents.last?.message == "final")
        XCTAssertTrue(totalEvents.first?.message == "test message 0!")
    }

}
