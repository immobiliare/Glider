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
    
    // MARK: - Private Properties
    
    private var writtenIDs = Set<String>()
    private var exp: XCTestExpectation?
    
    private let failureID = "failure"
    private let successID = "success"
    private let errorMessage = "something went very bad!"
    
    private var totalEventsToSent = 10
    private var blockSize = 5
    private var maxRetries = 2
    private var expectedRetriesCount: Int {
        (totalEventsToSent / blockSize) * maxRetries
    }
    private var countTotalRetries = 0
    private var flushInterval = Double(5)
    
    // MARK: - Tests
    
    func test_asyncTransportSucceded() async throws {
        try await prepareAsyncTransport(id: successID)
    }
    
    func test_asyncTransportRetries() async throws {
        try await prepareAsyncTransport(id: failureID)
    }
    
    // MARK: - Private Functions
    
    private func prepareAsyncTransport(id: String) async throws {
        exp = expectation(description: "test_\(id)")
        
        let format = FieldsFormatter(fields: [
            .level(style: .numeric),
            .delimiter(style: .tab),
            .message({
                $0.truncate = .tail(length: 4)
            })
        ])
        
        let asyncTransport = try AsyncTransportTestable({
            $0.bufferSize = 100
            $0.chunksSize = blockSize
            $0.flushInterval = flushInterval
            $0.formatters = [format]
            $0.bufferStorage = .inMemory
            $0.delegate = self
            $0.maxRetries = maxRetries
        })
        
        asyncTransport.id = id
        countTotalRetries = 0
        
        asyncTransport.onChunkToSend = { chunk, completion in
            // Validate the size of the block
            XCTAssert(chunk.count <= asyncTransport.configuration.chunksSize)
            
            // Validate the integrity of the event
            let anyPayload = chunk.randomElement()
            XCTAssertTrue(self.writtenIDs.contains(anyPayload!.event.id))
            XCTAssertTrue(anyPayload?.event.allExtra?.keys.contains("index") ?? false)
            XCTAssertTrue(anyPayload?.event.message.contains("test message ") ?? false)

            let formattedMsg = anyPayload?.message?.asString()
            XCTAssertTrue(formattedMsg == "6\ttest…")
            
            if asyncTransport.id == self.successID {
                completion(nil)
            } else {
                completion(AsyncError(message: self.errorMessage))
            }
        }
        
        let log = Log {
            $0.level = .debug
            $0.transports = [asyncTransport]
        }
        
        for i in 0..<totalEventsToSent {
            if let event = log.info?.write(event: {
                $0.message = "test message \(i)!"
                $0.extra = ["index": "\(i)"]
            }) {
                writtenIDs.insert(event.id)
            }
        }
        
        wait(for: [exp!], timeout: 100)
        
        if id == failureID {
            XCTAssertTrue(expectedRetriesCount == countTotalRetries)
        }
    }
    
    // MARK: - AsyncTransportDelegate
    
    func asyncTransport(_ transport: AsyncTransport, errorOccurred error: Error) {
        XCTFail(error.localizedDescription) // any logic error inside the internals must fail the test
    }
    
    func asyncTransport(_ transport: AsyncTransport,
                        willPerformRetriesOnEventIDs retryIDs: [(String, Int)],
                        discardedEvents: Set<String>, error: Error) {
        
        if discardedEvents.isEmpty == false {
            print("Will discard \(discardedEvents.count), too many attempts!")
            XCTAssertTrue((error as? AsyncError)?.message == self.errorMessage)
        }
        
        if retryIDs.isEmpty  == false {
            countTotalRetries += 1
            print("Will retry send for:  \(retryIDs.count) events")
            
            for retryID in retryIDs {
                XCTAssertTrue(retryID.1 <= maxRetries)
                print("    Added again to buffer \(retryID.0) (attempt= \(retryID.1))")
            }
        }
        
        writtenIDs.subtract(discardedEvents)
        if writtenIDs.isEmpty {
            XCTAssertTrue(try transport.countBufferedEvents() == 0)
            exp?.fulfill()
        }
    }
    
    func asyncTransport(_ transport: AsyncTransport, sentEventIDs: Set<String>) {
        print("Sent \(sentEventIDs.count) events: \(sentEventIDs)")
        let t = transport as! AsyncTransportTestable
        
        if t.id != successID {
            XCTFail("Not expecting success")
        }
        
        writtenIDs.subtract(sentEventIDs)

        if writtenIDs.isEmpty {
            exp?.fulfill()
        }
    }
    
    func asyncTransport(_ transport: AsyncTransport, discardedEventsFromBuffer: Int64) {
        print("Discarded sent for events: \(discardedEventsFromBuffer)")
        
        let t = transport as! AsyncTransportTestable
        if t.id != failureID {
            XCTFail("Not expecting failure")
        }
        
    }
    
    
}

fileprivate struct AsyncError: Error {
    var message: String
}

fileprivate class AsyncTransportTestable: AsyncTransport {
    
    var id = ""
    
    var onChunkToSend: ((_ chunk: [AsyncTransport.Chunk], _ completion: ((Error?) -> Void)) -> Void)?
    
    override func record(chunk: [AsyncTransport.Chunk], completion: ((Error?) -> Void)) {
        onChunkToSend?(chunk, completion)
    }
    
}
