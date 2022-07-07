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

/// The `WebSocketTransportClient`is used to transport message to a websocket compliant server.
/// Each message is transmitted to the server directly on record.
@available(iOS, introduced: 13)
public class WebSocketTransportClient: Transport, WebSocketClientDelegate {
    public typealias Payload = (event: Event, message: SerializableData?)
    
    // MARK: - Public Properties
    
    /// Configuration set.
    public let configuration: Configuration
    
    /// Minumum accepted level for this transport.
    /// `nil` means every passing message level is accepted.
    public var minimumAcceptedLevel: Level? = nil
    
    /// Transport is enabled.
    public var isEnabled: Bool = true
    
    /// GCD Queue.
    public var queue: DispatchQueue?
    
    /// Delegate.
    public weak var delegate: WebSocketTransportClientDelegate?
    
    /// WebSocket client.
    public private(set) var socket: WebSocketClient?
    
    /// Can socket accept data.
    public private(set) var isViable = false
    
    // MARK: - Private Properties
    
    /// Underlying async transport.
    private var asyncTransport: AsyncTransport?
    
    // MARK: - Initialization
    
    /// Initialize with a given configuration.
    ///
    /// - Parameters:
    ///   - configuration: configuration.
    ///   - delegate: delegate.
    public init(configuration: Configuration, delegate: WebSocketTransportClientDelegate? = nil) throws {
        self.configuration = configuration
        self.queue = configuration.queue
        self.delegate = delegate
        self.minimumAcceptedLevel = configuration.minimumAcceptedLevel

        self.socket = WebSocketClient(url: configuration.url,
                                      connectAutomatically: false,
                                      options: configuration.options,
                                      connectionQueue: configuration.socketQueue,
                                      delegate: self)
        
        if configuration.connectAutomatically {
            connect()
        }
    }
    
    /// Initialize a new `WebSocketTransport` instance with a given configuration.
    ///
    /// - Parameters:
    ///   - urlString: url of the remote websocket server.
    ///   - delegate: delegate to receive events.
    ///   - builder: builder configuration function.
    public convenience init(url urlString: String,
                delegate: WebSocketTransportClientDelegate? = nil,
                _ builder: ((inout Configuration) -> Void)? = nil) throws {
        
        guard let url = URL(string: urlString) else {
            throw GliderError(message: "Invalid WebSocket url: \(urlString)")
        }
        
        try self.init(configuration: Configuration(url: url, builder), delegate: delegate)
    }
    
    // MARK: - Public Functions
    
    /// Connect websocket.
    public func connect() {
        guard socket?.isConnected ?? false == false else {
            return
        }
        
        socket?.connect()
        delegate?.webSocketTransportConnecting(self)
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
        guard isEnabled else { return false }
        
        do {
            switch configuration.dataType {
            case .message:
                let message = self.configuration.formatters.format(event: event)
                
                if let messageAsString = message?.asString() {
                    socket?.send(string: messageAsString)
                } else if let messageAsData = message?.asData() {
                    socket?.send(data: messageAsData)
                } else {
                    return false
                }
                
            case .event(let encoder):
                let encoded = try encoder.encode(event)
                socket?.send(data: encoded)
            }
            
            return true
        } catch {
            delegate?.webSocketTransport(self, didReceiveError: error)
            return false
        }
    }
    
    // MARK: - WebSocketClientDelegate
    
    public func webSocketDidConnect(connection: WebSocketClient) {
        delegate?.webSocketTransport(self, didConnect: configuration.url)
    }
    
    public func webSocketDidDisconnect(connection: WebSocketClient, closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        delegate?.webSocketTransport(self, didDisconnectedWithCode: closeCode, reason: reason?.asString())
    }
    
    public func webSocketViabilityDidChange(connection: WebSocketClient, isViable: Bool) {
        self.isViable = isViable
        delegate?.webSocketTransport(self, isViable: isViable)
    }
    
    public func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketClient, NWError>) {
        if case .failure(let error) = result {
            delegate?.webSocketTransport(self, didReceiveError: error)
        }
    }
    
    public func webSocketDidReceiveError(connection: WebSocketClient, error: NWError) {
        delegate?.webSocketTransport(self, didReceiveError: error)
    }
    
    public func webSocketDidReceivePong(connection: WebSocketClient) {
        delegate?.webSocketTransportDidReceivePoing(self)
    }
    
    public func webSocketDidReceiveMessage(connection: WebSocketClient, string: String) {
        delegate?.webSocketTransport(self, didReceiveData: string)
    }
    
    public func webSocketDidReceiveMessage(connection: WebSocketClient, data: Data) {
        delegate?.webSocketTransport(self, didReceiveData: data)
    }
    
}

// MARK: - Configuration

extension WebSocketTransportClient {
    
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
        
        /// Formatters used to transform event in message.
        public var formatters = [EventFormatter]()
        
        /// Queue used for socket connection.
        /// By default is set to `.background`
        public var socketQueue = DispatchQueue.global(qos: .background)
        
        /// GCD Queue.
        public var queue = DispatchQueue(label: "Glider.\(UUID().uuidString)")
        
        /// What kind of data send.
        /// By default is send to `message` to send formatted message when available.
        public var dataType: WebSocketTransportDataType = .message
        
        /// Minumum accepted level for this transport.
        /// `nil` means every passing message level is accepted.
        public var minimumAcceptedLevel: Level? = nil
        
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
    
}

/// Data type to send to websocket endpoint.
/// - `message`: formatted message is sent, where available.
/// - `event`: the encoded message is sent.
public enum WebSocketTransportDataType {
    case message
    case event(encoder: JSONEncoder)
}
