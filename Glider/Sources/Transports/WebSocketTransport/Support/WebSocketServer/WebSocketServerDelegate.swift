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

@available(iOS, introduced: 13)
public protocol WebSocketServerDelegate: AnyObject {
    
    /// Called when websocket server's state did change.
    ///
    /// - Parameters:
    ///   - server: server instance.
    ///   - state: new state.
    func webSocketServer(_ server: WebSocketServer,
                         didChangeState state: NWListener.State)
    
    /// Called when server's client did disconnect.
    ///
    /// - Parameters:
    ///   - server: server instance.
    ///   - connection: connection.
    func webSocketServer(_ server: WebSocketServer,
                         didStopConnection connection: WebSocketPeer)
    
    /// Called when websocket server did end.
    ///
    /// - Parameters:
    ///   - server: server instance.
    ///   - error: if an error has occurred this is the error.
    func webSocketServer(_ server: WebSocketServer,
                         didStopServerWithError error: NWError?)

    /// Called when websocket client did connect.
    ///
    /// - Parameters:
    ///   - server: server instance.
    ///   - client: client connected.
    func webSocketServer(_ server: WebSocketServer,
                         didOpenConnection client: WebSocketPeer)
    
    /// Called when a websocket client did change state.
    ///
    /// - Parameters:
    ///   - server: state.
    ///   - peer: peer.
    ///   - state: new state.
    func webSocketServer(_ server: WebSocketServer,
                         peer: WebSocketPeer, didChangeState state: NWConnection.State)
    
    /// Called when server receive data from a connected client.
    ///
    /// - Parameters:
    ///   - server: server instance.
    ///   - peer: sender.
    ///   - data: data received.
    func webSocketServer(_ server: WebSocketServer,
                         peer: WebSocketPeer, didReceiveData data: Data)

    /// Called when server receive string from a connected client.
    ///
    /// - Parameters:
    ///   - server: server instance.
    ///   - peer: sender.
    ///   - string: string received.
    func webSocketServer(_ server: WebSocketServer,
                         peer: WebSocketPeer, didReceiveString string: String)

}
#endif
