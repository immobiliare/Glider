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

@available(iOS, introduced: 13)
public class WebSocketTransport: Transport, WebSocketClientDelegate {
    
    // MARK: - Public Properties
    
    /// Configuration set.
    public let configuration: Configuration
    
    /// GCD Queue.
    public var queue: DispatchQueue?
    
    /// WebSocket client.
    public private(set) var socket: WebSocketClient?
    
    // MARK: - Initialization
    
    public init(url urlString: String, _ builder: ((inout Configuration) -> Void)? = nil) throws {
        guard let url = URL(string: urlString) else {
            throw GliderError(message: "Invalid WebSocket url: \(urlString)")
        }
        
        self.configuration = Configuration(url: url, builder)
        self.queue = configuration.queue
        
        self.socket = WebSocketClient(url: configuration.url,
                                      connectAutomatically: configuration.connectAutomatically,
                                      options: configuration.options,
                                      connectionQueue: configuration.socketQueue,
                                      delegate: self)
    }
    
    // MARK: - Public Functions
    
    /// Connect websocket.
    public func connect() {
        guard socket?.isConnected ?? false == false else {
            return
        }
        
        socket?.connect()
    }
    
    /// Disconnect websocket.
    ///
    /// - Parameter closeCode: close code.
    public func disconnect(closeCode: NWProtocolWebSocket.CloseCode) {
        guard socket?.isConnected ?? false else {
            return
        }
        
        socket?.disconnect(closeCode: closeCode)
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        do {
            switch configuration.dataType {
            case .message:
                guard let message = self.configuration.formatters.format(event: event) else {
                    return false
                }
                
                if let messageAsString = message.asString() {
                    socket?.send(string: messageAsString)
                } else if let messageAsData = message.asData() {
                    socket?.send(data: messageAsData)
                } else {
                    return false
                }
                
            case .jsonEvent(let encoder):
                let encoded = try encoder.encode(event)
                socket?.send(data: encoded)
            }

            return true
        } catch {
            return false
        }
    }
    
    public func webSocketDidConnect(connection: WebSocketClient) {
        print("Connect")
    }
    
    public func webSocketDidDisconnect(connection: WebSocketClient, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        print("Disconnect: \(closeCode)")

    }
    
    public func webSocketViabilityDidChange(connection: WebSocketClient, isViable: Bool) {
    
    }
    
    public func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketClient, NWError>) {
        
    }
    
    public func webSocketDidReceiveError(connection: WebSocketClient, error: NWError) {
        print("Error: \(error)")
    }
    
    public func webSocketDidReceivePong(connection: WebSocketClient) {
        
    }
    
    public func webSocketDidReceiveMessage(connection: WebSocketClient, string: String) {
        print("Message: \(string)")
    }
    
    public func webSocketDidReceiveMessage(connection: WebSocketClient, data: Data) {
        print("Data: \(data)")
    }
    
    
}

// MARK: - Configuration

extension WebSocketTransport {
    
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// URL of the server side.
        public var url: URL
        
        /// `true` to connect on start.
        /// By default is set to `true`.
        public var connectAutomatically = true
        
        /// Options for connection.
        /// By default is set to `WebSocket.defaultOptions`.
        public var options: NWProtocolWebSocket.Options = WebSocketClient.defaultOptions
        
        /// Formatters set.
        ///
        /// NOTE:
        /// This is a derivate properties of the `AsyncTransport.Configuration`,
        /// it will set automatically the underlying AsyncTransport.Configuration.
        public var formatters: [EventFormatter] {
            set { asyncTransportConfiguration.formatters = newValue }
            get { asyncTransportConfiguration.formatters }
        }
        
        /// Limit cap for stored message.
        ///
        /// NOTE:
        /// This is a derivate properties of the `AsyncTransport.Configuration`,
        /// it will set automatically the underlying AsyncTransport.Configuration.
        public var maxEntries: Int {
            set { asyncTransportConfiguration.maxRetries = newValue }
            get { asyncTransportConfiguration.maxRetries }
        }

        /// Size of the chunks (number of payloads) sent at each dispatch event.
        ///
        /// NOTE:
        /// This is a derivate properties of the `AsyncTransport.Configuration`,
        /// it will set automatically the underlying AsyncTransport.Configuration.
        public var chunkSize: Int {
            set { asyncTransportConfiguration.chunksSize = newValue }
            get { asyncTransportConfiguration.chunksSize }
        }
        
        /// Automatic interval for flushing data in buffer.
        ///
        /// NOTE:
        /// This is a derivate properties of the `AsyncTransport.Configuration`,
        /// it will set automatically the underlying AsyncTransport.Configuration.
        public var autoFlushInterval: TimeInterval? {
            set { asyncTransportConfiguration.autoFlushInterval = newValue }
            get { asyncTransportConfiguration.autoFlushInterval }
        }
        
        /// Queue used for socket connection.
        /// By default is set to `.background`
        public var socketQueue = DispatchQueue.global(qos: .background)
        
        /// GCD Queue.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")
        
        /// What kind of data send.
        /// By default is send to `message` to send formatted message when available.
        public var dataType: DataType = .message
        
        // MARK: - Private Properties
        
        /// Configuration used to create the underlying `AsyncTransport`.
        public var asyncTransportConfiguration: AsyncTransport.Configuration = .init()
        
        // MARK: - Initialization
        
        /// Initialize a new configuration.
        ///
        /// - Parameters:
        ///   - url: URL of the configuration.
        ///   - builder: builder settings.
        public init(url: URL, _ builder: ((inout Configuration) -> Void)?) {
            self.url = url
            builder?(&self)
        }
        
    }
    
    /// Data type to send to websocket endpoint.
    /// - `message`: formatted message is sent, where available.
    /// - `jsonEvent`: the encoded message is sent.
    public enum DataType {
        case message
        case jsonEvent(encoder: JSONEncoder)
    }
    
}
