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
    
    private var asyncTransport: AsyncTransportTestable?
    
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
        
        asyncTransport = try AsyncTransportTestable(delegate: self, {
            $0.maxEntries = 100
            $0.chunksSize = self.blockSize
            $0.autoFlushInterval = self.flushInterval
            $0.formatters = [format]
            $0.bufferStorage = .inMemory
            $0.maxRetries = self.maxRetries
        })
        
        asyncTransport!.id = id
        countTotalRetries = 0
        
        let log = Log {
            $0.level = .trace
            $0.transports = [asyncTransport!]
        }
        
        for i in 0..<totalEventsToSent {
            if let event = log.info?.write({
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
    
    func asyncTransport(_ transport: AsyncTransport, canSendPayloadsChunk
                        chunk: AsyncTransport.Chunk, onCompleteSendTask
                        completion: @escaping ((ChunkCompletionResult) -> Void)) {
     
        // Validate the size of the block
        let t = transport as! AsyncTransportTestable
        XCTAssert(chunk.count <= t.configuration.chunksSize)
        
        // Validate the integrity of the event
        let anyPayload = chunk.randomElement()
        XCTAssertTrue(self.writtenIDs.contains(anyPayload!.event.id))
        XCTAssertTrue(anyPayload?.event.allExtra?.keys.contains("index") ?? false)
        XCTAssertTrue(anyPayload?.event.message.description.contains("test message ") ?? false)

        let formattedMsg = anyPayload?.message?.asString()
        XCTAssertTrue(formattedMsg == "6\ttest…")
        
        if t.id == self.successID {
            completion(.allSent)
        } else {
            let error = GliderError(message: self.errorMessage)
            completion(.chunkFailed(error))
        }
    }
    
    func asyncTransport(_ transport: AsyncTransport, didFailWithError error: Error) {
        XCTFail(error.localizedDescription) // any logic error inside the internals must fail the test
    }
    
    func asyncTransport(_ transport: AsyncTransport,
                        didFinishChunkSending sentEvents: Set<String>,
                        willRetryEvents unsentEventsToRetry: [String : Error],
                        discardedIDs: Set<String>) {
        
        if discardedIDs.isEmpty == false {
            print("Will discard \(discardedIDs.count), too many attempts!")
        }
        
        if unsentEventsToRetry.isEmpty  == false {
            countTotalRetries += 1
            print("Will retry send for:  \(unsentEventsToRetry.count) events")
            
            for retryID in unsentEventsToRetry.keys {
                print("    Added again to buffer \(retryID)")
            }
        }
        
        writtenIDs.subtract(discardedIDs)
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
    
}
