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

/// Represent a single peer connected to the WSServer instance.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, macCatalyst 13.0, *)
public class WebSocketPeer {
    
    // MARK: - Public properties
    
    /// Unique identifier of the connection.
    public let id: Int

    // MARK: - Internal Properties
    
    internal var didStopHandler: ((Error?) -> Void)?
    internal var didReceiveStringHandler: ((String) -> Void)?
    internal var didReceiveDataHandler: ((Data) -> Void)?
    internal var didChangeState: ((NWConnection.State) -> Void)?

    // MARK: - Private properties
    
    private enum ContextIdentifiers: String {
        case binaryContext
        case textContent
        case pongContext
    }
    
    /// Ticket for connection identifier.
    private static var nextID: Int = 0
    private let connection: NWConnection

    // MARK: - Initialization
    
    /// Initialize a new peer connection to the server.
    ///
    /// - Parameter connection: connection
    internal init(connection: NWConnection) {
        self.connection = connection
        self.id = Self.nextID
        Self.nextID += 1
    }

    // MARK: - Public Functions
    
    /// Send a string to the socket.
    ///
    /// - Parameter string: string message,
    
    /// Send data to the socket.
    ///
    /// - Parameters:
    ///   - data: data.
    ///   - contextID: context identifier
    public func send(string: String) {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: ContextIdentifiers.textContent.rawValue,
                                                  metadata: [metaData])
        self.send(data: string.data(using: .utf8), context: context)
    }
    
    /// Send data to the socket.
    ///
    /// - Parameters:
    ///   - data: data.
    ///   - contextID: context identifier
    public func send(data: Data, contextID: String = "binaryContext") {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: ContextIdentifiers.binaryContext.rawValue,
                                                  metadata: [metaData])
        self.send(data: data, context: context)
    }
    // MARK: - Private methods
    
    internal func stop() {
        
    }
    
    /// Initialize a new connection.
    /// You should not call this method directly, it will be called by the parent server.
    internal func start() {
        connection.stateUpdateHandler = self.stateDidChange(to:)
        listen()
        connection.start(queue: .global(qos: .background))
    }
    
    /// Called when a new message has been received.
    ///
    /// - Parameters:
    ///   - data: data.
    ///   - context: context.
    func receiveMessage(data: Data, context: NWConnection.ContentContext) {
        guard let metadata = context.protocolMetadata.first as? NWProtocolWebSocket.Metadata else {
            return
        }

        switch metadata.opcode {
        case .binary: // binary data
            didReceiveDataHandler?(data)
        case .text:
            guard let string = String(data: data, encoding: .utf8) else {
                return
            }
            didReceiveStringHandler?(string)
        case .cont: // continuation message
            break
        case .close: // a message indicating a close of connection
            break
        case .ping: // ping message
            pong()
        case .pong: // pong message
            break
        default:
            break
        }
    }

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidReceiveError(error)
        case .cancelled:
            stopConnection(error: nil)
        case .failed(let error):
            stopConnection(error: error)
        default:
            break
        }
        
        didChangeState?(state)
    }

    private func listen() {
        connection.receiveMessage { (data, context, _, error) in
            if let data = data, let context = context, !data.isEmpty {
                self.receiveMessage(data: data, context: context)
            }
            if let error = error {
                self.connectionDidReceiveError(error)
            } else {
                self.listen()
            }
        }
    }

    private func pong() {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .pong)
        let context = NWConnection.ContentContext(identifier: ContextIdentifiers.pongContext.rawValue,
                                                  metadata: [metaData])
        self.send(data: Data(), context: context)
    }

    private func send(data: Data?, context: NWConnection.ContentContext) {
        self.connection.send(content: data,
                             contentContext: context,
                             isComplete: true,
                             completion: .contentProcessed({ error in
                                if let error = error {
                                    self.connectionDidReceiveError(error)
                                    return
                                }
                             }))
    }

    private func connectionDidReceiveError(_ error: NWError) {

    }

    private func stopConnection(error: Error?) {
        connection.stateUpdateHandler = nil
        if let didStopHandler = didStopHandler {
            self.didStopHandler = nil
            didStopHandler(error)
        }
    }
    
}
#endif
