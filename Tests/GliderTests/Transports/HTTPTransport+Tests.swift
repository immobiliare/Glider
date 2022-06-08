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

final class HTTPTransportTests: XCTestCase, HTTPTransportDelegate {
    
    func test_HTTPTransportsSending() async throws {
        let exp = expectation(description: "Test")
        
        let transport = try HTTPTransport(delegate: self) {
            $0.maxConcurrentRequests = 3
            $0.formatters = [SysLogFormatter()]
            $0.maxEntries = 100
            $0.chunkSize = 5
            $0.autoFlushInterval = 5
        }
        
        let log = Log {
            $0.transports = [transport]
            $0.level = .debug
        }
        
        for i in 0..<50 {
            log.error?.write("test \(i)")
        }
        
        wait(for: [exp], timeout: 60)
    }
    
    func httpTransport(_ transport: HTTPTransport,
                       prepareURLRequestsForChunk chunk: AsyncTransport.Chunk) -> [HTTPTransportRequest] {
        
        chunk.map { event, message, attempt in
            var urlRequest = URLRequest(url: URL(string: "http://www.apple.com")!)
            urlRequest.httpBody = message?.asData()
            urlRequest.httpMethod = "POST"
            
            return HTTPTransportRequest(urlRequest: urlRequest) {
                $0.maxRetries = 2
            }
        }
        
    }
    
    func httpTransport(_ transport: HTTPTransport,
                       didFinishRequest request: HTTPTransportRequest,
                       withResult result: AsyncURLRequestOperation.Response) {
        print("Did complete: \(request.urlRequest.url): \(result)")
    }
    
}
