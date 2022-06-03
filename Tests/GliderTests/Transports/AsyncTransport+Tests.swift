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

final class AsyncTransportTests: XCTestCase, AsyncTransportDelegate {
    
    func test_asyncTransport() async throws {
        let exp = expectation(description: "test")
        
        let format = FieldsFormatter.default()
        format.structureFormatStyle = .object
        
        let asyncTransport = try AsyncTransport(bufferSize: 20,
                                                blockSize: 10,
                                                flushInterval: nil,
                                                formatters: [FieldsFormatter.default()],
                                                delegate: self)
        let log = Log {
            $0.level = .debug
            $0.transports = [asyncTransport]
        }
        
        for i in 0..<100 {
            log.info?.write(event: {
                $0.message = "test message \(i)!"
                $0.extra = ["index": "\(i)"]
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            asyncTransport.flush()
        }
        
        wait(for: [exp], timeout: 60)
        
    }
    
    func asyncTransport(_ transport: AsyncTransport, errorOccurred error: Error) {
        print("error \(error)")
    }
    
    func asyncTransport(_ transport: AsyncTransport, willPerformRetriesOnEventIDs: Set<String>, discardedEvents: Set<String>, error: Error) {
        print("willPerformRetriesOnEventIDs \(willPerformRetriesOnEventIDs)")

    }
    
    func asyncTransport(_ transport: AsyncTransport, sentEventIDs: Set<String>) {
        print("sent \(sentEventIDs)")

    }
    
    func asyncTransport(_ transport: AsyncTransport, discardedEventsFromBuffer: Int) {
        print("discsrded \(discardedEventsFromBuffer)")
    }
    
    
}
