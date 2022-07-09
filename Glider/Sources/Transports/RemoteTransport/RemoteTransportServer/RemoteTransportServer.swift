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

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#else
import AppKit
#endif

/// This class is used to provide a server which can handle and receive messages
/// from the `RemoteTransport` transport. We are using it in testing phase while
/// a more complete implementation is used by the GliderViewer app to provide
/// a server where SDKs can connect and send messages.
public class RemoteTransportServer {
    
    // MARK: - Public Properties
    
    /// Name of the service.
    public let serviceName: String
    
    /// Type of service.
    public let serviceType: String
    
    /// Listening port.
    public let port: NWEndpoint.Port
    
    /// Events delegate.
    public weak var delegate: RemoteTransportServerDelegate?
    
    /// Server current state.
    public private(set) var currentState: NWListener.State = .cancelled
    
    /// Connected clients.
    public private(set) var clients = [ClientId: Client]()
    
    // MARK: - Private Properties
    
    /// Network listener.
    private var listener: NWListener?
    
    /// Identify when server is started.
    private(set) var isStarted = false
    
    /// Active connections.
    private var connections = [ConnectionId: RemoteTransport.Connection]()

    // MARK: - Initialization
    
    /// Initialize a new server.
    ///
    /// - Parameters:
    ///   - serviceName: service name; when not set the current host machine name is used.
    ///   - serviceType: service type.
    ///   - port: port of listening; when not specified `any` is used.
    public init(serviceName: String = RemoteTransportServer.currentMachineName(),
                serviceType: String = RemoteTransport.Configuration.defaultServiceType,
                port: UInt16? = nil) {
        self.port = (port != nil ? .init(rawValue: port!)! : .any)
        self.serviceName = serviceName
        self.serviceType = serviceType
    }
    
    /// Get the current device name.
    /// - Returns: `String`
    public static func currentMachineName() -> String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.name
        #elseif os(watchOS)
        return WKInterfaceDevice.current()
        #else
        return Host.current().localizedName ?? "Unknown"
        #endif
    }
    
    // MARK: - Public Functions
    
    /// Start listening server.
    public func start() throws {
        guard !isStarted else { return }

        delegate?.remoteTransportServer(self, willStartPublishingService: serviceType)
        
        let listener: NWListener
        listener = try NWListener(using: .tcp, on: port)

        isStarted = true

        listener.service = NWListener.Service(name: serviceName, type: serviceType)
        
        listener.stateUpdateHandler = { [weak self] state in
            self?.didUpdateState(state)
        }
        
        listener.newConnectionHandler = { [weak self] connection in
            self?.didReceiveNewConnection(connection)
        }
        
        listener.start(queue: .main)
        self.listener = listener
    }
    
    // MARK: - Private Functions
    
    /// Called when the state of the server did change.
    ///
    /// - Parameter newState: new state.
    private func didUpdateState(_ newState: NWListener.State) {
        delegate?.remoteTransportServer(self, didChangeState: newState)
        self.currentState = newState
        
        if case .failed = newState {
            self.scheduleListenerRetry()
        }
    }
    
    /// Schedule a new session of retry for service.
    private func scheduleListenerRetry() {
        guard isStarted else { return }

        // Automatically retry until the user cancels
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
            try? self?.start()
        }
    }
    
    /// Used when a new client did connect.
    ///
    /// - Parameter connection: connection instance.
    private func didReceiveNewConnection(_ connection: NWConnection) {
        delegate?.remoteTransportServer(self, didReceiveNewConnection: connection)
        
        let connection = RemoteTransport.Connection(connection)
        connection.delegate = self
        connection.start(on: .main)
        
        let id = ConnectionId(connection)
        connections[id] = connection
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(15)) { [weak self] in
            self?.connections[id] = nil
        }
    }
    
    private func didReceivePacket(_ rawPacket: RemoteTransport.Connection.RawPacket,
                                  fromConnection connection: RemoteTransport.Connection) throws {
        
        let client: Client? = clients.values.first(where: { $0.connection === connection })
        
        guard let code = rawPacket.readableCode else {
            throw GliderError(message: "Unknown/unsupported code for event received or client not found")
        }
        
        switch code {
        case .clientHello: // Device wants to connect
            if let packet = try RemoteTransport.PacketHello.decode(rawPacket) {
                didReceiveConnectionRequestFromClient(connection, request: packet)
            }
            
        case .message: // Received a new log message
            if let client = client, let packet = try RemoteTransport.PacketEvent.decode(rawPacket) {
                delegate?.remoteTransportServer(self, client: client, didReceiveEvent: packet.event)
            }
            
        case .ping: // Received ping message.
            client?.didReceivePing()
         
        default:
            break
        }
    }
    
    private func didReceiveConnectionRequestFromClient(_ connection: RemoteTransport.Connection, request: RemoteTransport.PacketHello) {
        let clientId = ClientId(request: request)
        
        if let client = clients[clientId] {
            client.connection = connection
            client.didConnectExistingClient()
            delegate?.remoteTransportServer(self, didConnectedClient: client)
        } else {
            let client = Client(request: request)
            client.connection = connection
            clients[clientId] = client
            delegate?.remoteTransportServer(self, didConnectedClient: client)
        }
        
        connection.sendEmptyPacket(withCode: .serverHello)
    }
    
}

// MARK: - RemoteTransportConnectionDelegate

extension RemoteTransportServer: RemoteTransportConnectionDelegate {
    
    public func connection(_ connection: RemoteTransport.Connection, didChangeState newState: NWConnection.State) {
        delegate?.remoteTransportServer(self, connection: connection, didChangeState: newState)

        switch newState {
        case .failed, .cancelled: // remove connection
            connections[ConnectionId(connection)] = nil
        default:
            break
        }
    }
    
    public func connection(_ connection: RemoteTransport.Connection, didReceiveEvent event: RemoteTransport.Connection.Event) {
        switch event {
        case .packet(let packet):
            try? didReceivePacket(packet, fromConnection: connection)
        case .error:
            break
        case .completed:
            break
        }
    }
    
    public func connection(_ connection: RemoteTransport.Connection, failedToSendPacket packet: RemoteTransportPacket, error: Error) {
        print("error")
    }
    
    public func connection(_ connection: RemoteTransport.Connection, failedToDecodingPacketData data: Data, error: Error) {
        print("data")
    }
    
}

// MARK: - ConnectionId

extension RemoteTransportServer {
    
    fileprivate struct ConnectionId: Hashable {
        let id: ObjectIdentifier
        
        init(_ connection: RemoteTransport.Connection) {
            self.id = ObjectIdentifier(connection)
        }
    }
    
}
