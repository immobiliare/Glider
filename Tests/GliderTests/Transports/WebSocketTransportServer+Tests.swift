//
//  Glider
//  Fast, Lightweight yet powerful logging system for Swift.
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

#if canImport(Network)
import Foundation
import Network

import XCTest
@testable import Glider
import CloudKit

class WebSocketTransportServerTests: XCTestCase, WebSocketTransportServerDelegate, WebSocketClientDelegate {
    
    // MARK: - Private Properties
    
    private var clientA: WebSocketClient?
    private var clientB: WebSocketClient?
    private var port: UInt16 = 1010
    private var countConnectedClients = 0
    
    private var expServerReady: XCTestExpectation?
    private var expClientConnected: XCTestExpectation?
    private var expMessagesReceivedA: XCTestExpectation?
    private var expMessagesReceivedB: XCTestExpectation?

    private var messagesToSent = 100
    private var messagesReceivedA = [String]()
    private var messagesReceivedB = [String]()
    private var expectedMessages = [String]()

    private var isFulfilledA = false
    private var isFulfilledB = false

    func tests_webSocketTransport() async throws {
        // Prepare formatter
        let format = FieldsFormatter(fields: [
            .message({
                $0.truncate = .head(length: 10)
            }),
        ])
        
        expServerReady = expectation(description: "Expecting server ready")
        expClientConnected = expectation(description: "Expecting connected clients")
        
        // Prepare transport...
        let transport = try WebSocketTransportServer(port: port, delegate: self, {
            $0.startImmediately = true
            $0.formatters = [format]
        })
        
        // Expecting server ready
        wait(for: [expServerReady!], timeout: 10)
        
        let url = URL(string: "ws://localhost:\(port)")!
        
        self.clientA = WebSocketClient(url: url)
        self.clientA?.delegate = self
        self.clientB = WebSocketClient(url: url)
        self.clientB?.delegate = self
        
        self.clientA?.connect()
        self.clientB?.connect()
                
        wait(for: [expClientConnected!], timeout: 10)

        expMessagesReceivedA = expectation(description: "Expecting messages received from client A")
        expMessagesReceivedB = expectation(description: "Expecting messages received from client B")

        let log = Log {
            $0.level = .debug
            $0.transports = [transport]
        }
        
        for i in 0..<messagesToSent {
            let messageText = "message \(i)"
            expectedMessages.append(messageText)
            
            log.info?.write(msg: .init(stringLiteral: messageText))
        }
        
        wait(for: [expMessagesReceivedA!, expMessagesReceivedB!], timeout: 10)
        
        XCTAssertEqual(messagesReceivedA.count, messagesToSent)
        XCTAssertEqual(messagesReceivedB.count, messagesToSent)
        
        XCTAssertEqual(expectedMessages, messagesReceivedA)
        XCTAssertEqual(expectedMessages, messagesReceivedB)

        transport.stop()
        clientA?.disconnect()
        clientB?.disconnect()
    }
    
    // MARK: - WebSocketServerTransportDelegate
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didChangeState newState: NWListener.State) {
        if newState == .ready {
            expServerReady?.fulfill()
        }
    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didStartBonjour identifier: String, name: String) {
        
    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didStopBonjour error: Error?) {
        
    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didReceiveError error: Error?) {
        
    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didConnectPeer peer: WebSocketPeer) {
        countConnectedClients += 1
        if countConnectedClients == 2 {
            expClientConnected?.fulfill()
        }
    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, peer: WebSocketPeer, didChangeState state: NWConnection.State) {
        
    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didDisconnectPeer peer: WebSocketPeer) {

    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didDisconnect error: NWError?) {
        
    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didReceiveData data: Data, fromPeer peer: WebSocketPeer) {
        
    }
    
    func webSocketServerTransport(_ transport: WebSocketTransportServer, didReceiveString string: String, fromPeer peer: WebSocketPeer) {
        
    }
    
    // MARK: - WebSocketClientDelegate
    
    func webSocketDidConnect(connection: WebSocketClient) {
        
    }
    
    func webSocketDidDisconnect(connection: WebSocketClient, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        
    }
    
    func webSocketViabilityDidChange(connection: WebSocketClient, isViable: Bool) {
        
    }
    
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketClient, NWError>) {
        
    }
    
    func webSocketDidReceiveError(connection: WebSocketClient, error: NWError) {
        
    }
    
    func webSocketDidReceivePong(connection: WebSocketClient) {
        
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketClient, string: String) {
        if connection === clientA {
            messagesReceivedA.append(string)
        } else {
            messagesReceivedB.append(string)
        }
        
        if messagesReceivedA.count == messagesToSent && !isFulfilledA {
            isFulfilledA = true
            expMessagesReceivedA?.fulfill()
        }
        
        if messagesReceivedB.count == messagesToSent && !isFulfilledB {
            isFulfilledB = true
            expMessagesReceivedB?.fulfill()
        }
    }
    
    func webSocketDidReceiveMessage(connection: WebSocketClient, data: Data) {
        
    }

}
#endif
