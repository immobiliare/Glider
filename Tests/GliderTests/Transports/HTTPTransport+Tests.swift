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
import Darwin.C

final class HTTPTransportTests: XCTestCase, HTTPTransportDelegate, HTTPServerDelegate {
    
    // MARK: - Private Properties
    
    private var messagesToSent = 1 //5
    private var countReceived = 0
    private var countErrors = 0
    private var expReceivedMessages: XCTestExpectation?
    private var expServerStart: XCTestExpectation?
    private let port = UInt16(8080)
    private var serverSocket: HTTPServer?
    private var anErrorTriggered = false
    
    // MARK: - Test
    
    func test_HTTPTransportsSending() async throws {
        expServerStart = expectation(description: "Expecting server to start")

        // Start an http server to test data
        serverSocket = HTTPServer()
        serverSocket?.delegate = self
        try serverSocket?.start(port: port)
        
        expReceivedMessages = expectation(description: "Expecting received messages")
        
        print("Starting http test web server at port \(port)...")

        let transport = try HTTPTransport(delegate: self) {
            $0.maxConcurrentRequests = 3
            $0.formatters = [SysLogFormatter()]
            $0.maxEntries = 100
            $0.chunkSize = 5
            $0.autoFlushInterval = 5
        }
        
        wait(for: [expServerStart!], timeout: 5)
        print("Now sending logs to http transport...")

        let log = Log {
            $0.transports = [transport]
            $0.level = .debug
        }
        
        // Send some logs
        for i in 0..<messagesToSent {
            log.error?.write(msg: "Message \(i)")
        }
        
        print("Waiting for being received...")
        wait(for: [expReceivedMessages!], timeout: 20)
        
        serverSocket?.stop()
    }
    
    // MARK: - HTTPTransportDelegate
    
    func httpTransport(_ transport: HTTPTransport,
                       prepareURLRequestsForChunk chunk: AsyncTransport.Chunk) -> [HTTPTransportRequest] {
        
        chunk.map { event, message, attempt in
            var urlRequest = URLRequest(url: URL(string: "http://127.0.0.1:\(port)")!)
            urlRequest.httpBody = message?.asData()
            urlRequest.httpMethod = "POST"
            urlRequest.timeoutInterval = 10
            
            if anErrorTriggered {
                XCTAssertEqual(attempt, 1) // check retry
            }
            
            return HTTPTransportRequest(urlRequest: urlRequest) {
                $0.maxRetries = 2
                $0.shouldRetryRequestHandler = { error in
                    // always retry the call
                    return true
                }
            }
        }
        
    }
    
    func httpTransport(_ transport: HTTPTransport,
                       didFinishRequest request: HTTPTransportRequest,
                       withResult result: AsyncURLRequestOperation.Response) {
                
        switch result {
        case .failure(let error):
            print("Failed to send data: \(error.localizedDescription)")
            countErrors += 1
        case .success:
            print("Data sent successfully!")
            countReceived += 1
        }
        
        if countReceived == messagesToSent && countErrors == 1 {
            print("Received \(countReceived)/\(messagesToSent) with errors: \(countErrors) to retry")
            expReceivedMessages!.fulfill()
        }
    }
    
    // MARK: - HTTPRequestHandler
    
    func serverDidChangeState(_ server: HTTPServer, state: HTTPServer.HTTPServerState) {
        if state == .running {
            expServerStart!.fulfill()
        }
    }
    
    func server(_ server: HTTPServer, didReceiveRequest request: CFHTTPMessage, fileHandle: FileHandle, completion: @escaping () -> Void) {
        let url = CFHTTPMessageCopyRequestURL(request)!.takeRetainedValue() as URL
        let method = CFHTTPMessageCopyRequestMethod(request)!.takeRetainedValue() as String

        switch (method, url.path) {
        case ("POST", "/"):
            
            if anErrorTriggered == false {
                anErrorTriggered = true
                
                // Fallback error
                let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, nil, kCFHTTPVersion1_1).takeRetainedValue()
                CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain" as CFString)
                CFHTTPMessageSetBody(response, "405 Method Not Allowed".data(using: .ascii)! as CFData)
                assert(CFHTTPMessageIsHeaderComplete(response))
                let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data

                
                fileHandle.write(data)
            } else {
                // Echo response
                let data = CFHTTPMessageCopySerializedMessage(request)!.takeRetainedValue() as Data
                let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, nil, kCFHTTPVersion1_1).takeRetainedValue()
                CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "application/json" as CFString)
                CFHTTPMessageSetBody(response, data as CFData)
                assert(CFHTTPMessageIsHeaderComplete(response))
                
                fileHandle.write(data)
            }
            completion()
        default:
            // Fallback error
            let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, nil, kCFHTTPVersion1_1).takeRetainedValue()
            CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain" as CFString)
            CFHTTPMessageSetBody(response, "405 Method Not Allowed".data(using: .ascii)! as CFData)
            assert(CFHTTPMessageIsHeaderComplete(response))
            let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
            
            fileHandle.write(data)
            completion()
        }
    }
    
}
