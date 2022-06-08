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
import Network

import XCTest
@testable import Glider
import CloudKit

class WebSocketTransportTests: XCTestCase, WebSocketServerDelegate {
    
    
    private lazy var webSocketServer: WebSocketServer = {
        let server = WebSocketServer(port: 1010)
        return server
    }()
    
    func tests_webSocketTransport() async throws {
        let exp = expectation(description: "tests_throttledTransportBufferFlush")
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])
        format.structureFormatStyle = .object
    
        webSocketServer.delegate = self
        try webSocketServer.start()
        
        let transport = try WebSocketTransport(url: "wss://127.0.0.1:1010") {
            $0.connectAutomatically = true
            $0.formatters = [format]
        }
                
        let log = Log {
            $0.level = .debug
            $0.transports = [transport]
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
            for i in 0..<1 {
                log.info?.write("ciao \(i)")
            }
        })
                
        wait(for: [exp], timeout: 500)
        
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        webSocketServer.stop()
    }
    
    func webSocketServer(_ server: WebSocketServer, didChangeState state: NWListener.State) {
        
    }
    
    func webSocketServer(_ server: WebSocketServer, didStopConnection connection: WebSocketPeer) {
        
    }
    
    func webSocketServer(_ server: WebSocketServer, didStopServerWithError error: NWError?) {
        
    }
    
    func webSocketServer(_ server: WebSocketServer, didOpenConnection client: WebSocketPeer) {
        print("Open connection!")
    }
    
    func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didChangeState state: NWConnection.State) {
        
    }
    
    func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didReceiveData data: Data) {
        print("Receive string: \(data)")
        print("Resend same data")
        peer.send(data: data)
    }
    
    func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didReceiveString string: String) {
        print("Receive string: \(string)")
        print("Sent string uppercased")
        peer.send(string: string.uppercased())
    }
}
