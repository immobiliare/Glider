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

#if canImport(Network)
import Foundation
import Network

/// `WebSocketTransportClientDelegate` allows to receive notifications from a `WebSocketTransportClient`.
public protocol WebSocketTransportClientDelegate: AnyObject {
    
    // MARK: - Connection Related
    
    /// Message sent when connection is in progress.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    func webSocketTransportConnecting(_ transport: WebSocketTransportClient)
    
    /// Message sent when web transport client state did change.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - newState: new state.
    func webSocketTransport(_ transport: WebSocketTransportClient,
                            didChangeState newState: NWConnection.State)

    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - url: url of the remote side
    func webSocketTransport(_ transport: WebSocketTransportClient,
                            didConnect url: URL)
    
    /// Message sent when client did disconnect.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - code : disconnection code.
    ///   - reason: readable reason of disconnection.
    func webSocketTransport(_ transport: WebSocketTransportClient,
                            didDisconnectedWithCode code: NWProtocolWebSocket.CloseCode,
                            reason: String?)
    
    /// Message sent when an error has received from transport.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - error: error received.
    func webSocketTransport(_ transport: WebSocketTransportClient,
                            didReceiveError error: Error?)
    
    /// Message received as response from a ping.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    func webSocketTransportDidReceivePoing(_ transport: WebSocketTransportClient)
    
    /// Message triggered when a new data from server has been received.
    ///
    /// - Parameters:
    ///   - transport: trasnport instance.
    ///   - data: data received.
    func webSocketTransport(_ transport: WebSocketTransportClient,
                            didReceiveData data: SerializableData?)
    
    /// Tells the delegate that the WebSocket connection viability has changed.
    ///
    /// - Parameters:
    ///   - transport: trasnport instance.
    ///   - isViable: A `Bool` indicating if the connection is viable or not.
    func webSocketTransport(_ transport: WebSocketTransportClient,
                            isViable: Bool)

    // MARK: - Payloads Events
    
    /// Message triggered when a a transport send a new payload to remote side.
    ///
    /// - Parameters:
    ///   - transport: transport instance.
    ///   - payload: payload sent.
    ///   - error: error if sending fails.
    func webSocketTransport(_ transport: WebSocketTransportClient,
                            didSendPayload payload: WebSocketTransportClient.Payload, error: Error?)
    
}
#endif
