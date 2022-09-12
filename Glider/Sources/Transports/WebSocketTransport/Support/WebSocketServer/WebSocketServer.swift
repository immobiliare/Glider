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
public class WebSocketServer {
    
    // MARK: - Public Properties
    
    /// Delegate class.
    public weak var delegate: WebSocketServerDelegate?
    
    /// Return `true` if websocket is started.
    public var isStarted: Bool {
        listener != nil
    }
    
    /// List active connections to the server.
    public var connections: [WebSocketPeer] {
        Array(connectionsByID.values)
    }
    
    /// Connection port.
    public let port: NWEndpoint.Port

    // MARK: - Private Properties
    
    /// Server core.
    private var listener: NWListener?
    
    /// Server parameters.
    private let parameters: NWParameters
    
    /// Connected peers.
    private var connectionsByID: [Int: WebSocketPeer] = [:]
    
    /// Initialize a new WebSocket server.
    ///
    /// - Parameters:
    ///   - port: port of listening.
    ///   - parameters: network parameters settings.
    ///   - options: websocket options.
    ///   - `delegate`: delegate.
    public init(port: UInt16,
                parameters: NWParameters? = nil,
                options: NWProtocolWebSocket.Options? = nil,
                delegate: WebSocketServerDelegate? = nil) {
        
        self.port = NWEndpoint.Port(rawValue: port)!
        self.delegate = delegate

        if let passedParameters = parameters {
            self.parameters = passedParameters
        } else {
            self.parameters = NWParameters(tls: nil)
            self.parameters.allowLocalEndpointReuse = true
            self.parameters.includePeerToPeer = true
        }
        
        var wsOptions = options
        if wsOptions == nil {
            wsOptions = NWProtocolWebSocket.Options()
            wsOptions?.autoReplyPing = true
        }
        
        self.parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions!, at: 0)
    }
    
    // MARK: - Public methods
    
    /// Start server and accept new connections.
    ///
    /// - Throws: throw an exception if something fails.
    public func start() throws {
        if listener == nil {
            listener = try NWListener(using: parameters, on: self.port)
        }
        
        listener?.stateUpdateHandler = self.stateDidChange(to:)
        listener?.newConnectionHandler = self.didAccept(connection:)
        listener?.start(queue: .main)
    }
    
    /// Stop server.
    public func stop() {
        listener?.cancel()
    }
    
    /// Send data to all connected peers.
    ///
    /// - Parameter data: data.
    public func send(data: Data) {
        connectionsByID.values.forEach { peer in
            peer.send(data: data)
        }
    }
    
    /// Send string to all connected peers.
    ///
    /// - Parameter string: string.
    public func send(string: String) {
        connectionsByID.values.forEach { peer in
            peer.send(string: string)
        }
    }
    
    // MARK: - Private Functions

    private func didAccept(connection: NWConnection) {
        let connection = WebSocketPeer(connection: connection)
        connectionsByID[connection.id] = connection
        
        connection.start()
        
        connection.didStopHandler = { _ in
            self.connectionDidStop(connection)
        }
        
        connection.didReceiveStringHandler = { [unowned self] string in
            self.connectionsByID.values.forEach { peer in
                delegate?.webSocketServer(self, peer: peer, didReceiveString: string)
            }
        }
        
        connection.didReceiveDataHandler = { [unowned self] data in
            connectionsByID.values.forEach { peer in
                delegate?.webSocketServer(self, peer: peer, didReceiveData: data)
            }
        }
        
        connection.didChangeState = { [unowned self] state in
            delegate?.webSocketServer(self, peer: connection, didChangeState: state)
        }
        
        delegate?.webSocketServer(self, didOpenConnection: connection)
    }

    private func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .cancelled:
            self.stopSever(error: nil)
        case .failed(let error):
            self.stopSever(error: error)
        default:
            break
        }
        
        delegate?.webSocketServer(self, didChangeState: newState)
    }

    private func connectionDidStop(_ connection: WebSocketPeer) {
        self.connectionsByID.removeValue(forKey: connection.id)
        
        delegate?.webSocketServer(self, didStopConnection: connection)
    }

    private func stopSever(error: NWError?) {
        self.listener = nil
        for connection in self.connectionsByID.values {
            connection.didStopHandler = nil
            connection.stop()
        }
        self.connectionsByID.removeAll()
        
        delegate?.webSocketServer(self, didStopServerWithError: error)
    }
    
}
#endif
