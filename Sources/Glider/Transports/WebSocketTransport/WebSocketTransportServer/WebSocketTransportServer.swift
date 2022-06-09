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

/// The `WebSocketTransport`is used to transport message to a websocket compliant server.
/// Each message is transmitted to the server directly on record.
@available(iOS, introduced: 13)
public class WebSocketTransportServer: Transport, WebSocketServerDelegate {
    
    // MARK: - Public Properties
    
    /// GCD queue
    public var queue: DispatchQueue?
    
    /// Configuration.
    public let configuration: Configuration
    
    // MARK: - Private Properties
    
    /// WebSocket Server
    private var server: WebSocketServer?
    
    // MARK: - Initialization
    
    /// Initialize a new server transport.
    ///
    /// - Parameters:
    ///   - port: port of the server.
    ///   - builder: builder configuration.
    public init(port: UInt16, _ builder: ((inout Configuration) -> Void)? = nil) throws {
        self.configuration = Configuration(port: port, builder)
        self.server = WebSocketServer(port: port,
                                      parameters: configuration.parameters,
                                      options: configuration.options,
                                      delegate: self)
        
        if configuration.startImmediately {
            try server?.start()
        }
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        true
    }
    
    // MARK: - WebSocketServerDelegate
    
    public func webSocketServer(_ server: WebSocketServer, didChangeState state: NWListener.State) {
        
    }
    
    public func webSocketServer(_ server: WebSocketServer, didStopConnection connection: WebSocketPeer) {
        
    }
    
    public func webSocketServer(_ server: WebSocketServer, didStopServerWithError error: NWError?) {
        
    }
    
    public func webSocketServer(_ server: WebSocketServer, didOpenConnection client: WebSocketPeer) {
        
    }
    
    public func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didChangeState state: NWConnection.State) {
        
    }
    
    public func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didReceiveData data: Data) {
        
    }
    
    public func webSocketServer(_ server: WebSocketServer, peer: WebSocketPeer, didReceiveString string: String) {
        
    }
    
}
