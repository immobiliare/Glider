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

public protocol WebSocketTransportDelegate: AnyObject {
    
    // MARK: - Connection Related
    
    /// Message sent when connection is in progress.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    func webSocketTransportConnecting(_ transport: WebSocketTransport)
    
    /// Message sent when web transport client state did change.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - newState: new state.
    func webSocketTransport(_ transport: WebSocketTransport,
                            didChangeState newState: NWConnection.State)

    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - url: url of the remote side
    func webSocketTransport(_ transport: WebSocketTransport,
                            didConnect url: URL)
    
    /// Message sent when client did disconnect.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - code : disconnection code.
    ///   - reason: readable reason of disconnection.
    func webSocketTransport(_ transport: WebSocketTransport,
                            didDisconnectedWithCode code: NWProtocolWebSocket.CloseCode,
                            reason: String?)
    
    /// Message sent when an error has received from transport.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - error: error received.
    func webSocketTransport(_ transport: WebSocketTransport,
                            didReceiveError error: Error?)
    
    /// Message received as response from a ping.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    func webSocketTransportDidReceivePoing(_ transport: WebSocketTransport)
    
    /// Message triggered when a new data from server has been received.
    ///
    /// - Parameters:
    ///   - transport: trasnport instance.
    ///   - data: data received.
    func webSocketTransport(_ transport: WebSocketTransport,
                            didReceiveData data: SerializableData?)
    
    
    /// Tells the delegate that the WebSocket connection viability has changed.
    ///
    /// - Parameters:
    ///   - transport: trasnport instance.
    ///   - isViable: A `Bool` indicating if the connection is viable or not.
    func webSocketTransport(_ transport: WebSocketTransport,
                            isViable: Bool)

    // MARK: - Payloads Events
    
    /// Message triggered when a a transport send a new payload to remote side.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - payload: payload sent.
    ///   - error: error if sending fails.
    func webSocketTransport(_ transport: WebSocketTransport,
                            didSendPayload payload: WebSocketTransport.Payload, error: Error?)
    
}
