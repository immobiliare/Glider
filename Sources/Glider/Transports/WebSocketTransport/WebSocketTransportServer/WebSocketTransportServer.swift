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
public class WebSocketTransportServer: Transport, WebSocketServerDelegate, BonjourPublisherDelegate {
    
    // MARK: - Public Properties
    
    /// GCD queue
    public var queue: DispatchQueue?
    
    /// Configuration.
    public let configuration: Configuration
    
    /// Delegate for events.
    public weak var delegate: WebSocketTransportServerDelegate?
    
    // MARK: - Private Properties
    
    /// WebSocket Server
    private var server: WebSocketServer?
    
    /// If enabled this is the class which publish the service over bonjour.
    private var bonjour: BonjourPublisher?
    
    // MARK: - Initialization
    
    /// Initialize a new server transport.
    ///
    /// - Parameters:
    ///   - port: port of the server.
    ///   - builder: builder configuration.
    public init(port: UInt16, delegate: WebSocketTransportServerDelegate? = nil,
                _ builder: ((inout Configuration) -> Void)? = nil) throws {
        self.configuration = Configuration(port: port, builder)
        self.delegate = delegate
        self.server = WebSocketServer(port: port,
                                      parameters: configuration.parameters,
                                      options: configuration.options,
                                      delegate: self)
        
        if var bonjourConfiguration = configuration.bonjourConfiguration {
            bonjourConfiguration.txtRecords = bonjourConfiguration.txtRecords.merging([
                "wsPort": String(Int32(configuration.port))
            ], uniquingKeysWith: { (_, new) in new })
            
            self.bonjour = BonjourPublisher(configuration: bonjourConfiguration)
            self.bonjour?.delegate = self
        }
        
        if configuration.startImmediately {
            try start()
        }
    }
    
    // MARK: - Public Functions
    
    /// Start websocket server.
    ///
    /// - Throws: throw an exception if something fails.
    open func start() throws {
        guard server?.isStarted ?? false == false else {
            return
        }
        
        try server?.start() // start server
        startAdvertisingService()
    }
    
    /// Stop websocket server.
    open func stop() {
        guard server?.isStarted ?? false else {
            return
        }
        
        server?.stop()
        stopAdvertisingService()
    }

    /// Start advertising bonjour publish.
    open func startAdvertisingService() {
        guard bonjour?.started ?? false == false else {
            return
        }
        
        bonjour?.start()
    }
    
    /// Stop advertising service on bonjour.
    open func stopAdvertisingService() {
        guard bonjour?.started ?? false == true else {
            return
        }
        
        bonjour?.stop()
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        guard server?.isStarted ?? false else {
            return false
        }
        
        let message = configuration.formatters.format(event: event)
        if let messageAsString = message?.asString() {
            server?.send(string: messageAsString)
        } else if let messageAsData = message?.asData() {
            server?.send(data: messageAsData)
        } else {
            return false
        }
        
        return true
    }
    
    // MARK: - BomjourPublisherDelegate
    
    open func bonjourPublisherDidStart(_ publisher: BonjourPublisher) {
        delegate?.webSocketServerTransport(self,
                                           didStartBonjour: publisher.configuration.identifier,
                                           name: publisher.configuration.name)
    }
    
    open func bonjourPublisher(_ publisher: BonjourPublisher, didStopWithError error: Error?) {
        delegate?.webSocketServerTransport(self, didStopBonjour: error)
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

// MARK: - WebSocketTransportServer.Configuration

extension WebSocketTransportServer {
    
    public struct Configuration {
        
        /// When set the WebSocketTransportServer service will be also
        /// published over the local network via Bonjour services.
        /// This allows local clients to connect.
        public var bonjourConfiguration: BonjourPublisher.Configuration?
        
        /// Port where the socket is listening.
        public var port: UInt16
        
        /// `true` to start the service immediately (by default is `true`)
        public var startImmediately: Bool = true
        
        /// Data formatter.
        public var formatters = [EventFormatter]()
        
        /// Options for NWProtocol.
        public var options: NWProtocolWebSocket.Options?
        
        /// Parameters for NW.
        public var parameters: NWParameters?
        
        // MARK: - Initialization
        
        /// Initialize a new configuration for `WebSocketTransportServer`
        /// - Parameters:
        ///   - port: port of the server connection.
        ///   - builder: builder for extra configuration.
        public init(port: UInt16, _ builder: ((inout Configuration) -> Void)? = nil) {
            self.port = port
            builder?(&self)
        }
    }
    
}
