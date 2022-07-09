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
import Glider

public protocol RemoteTransportServerDelegate: AnyObject {
    
    func remoteTransportServer(_ server: RemoteTransportServer, willStartPublishingService serviceName: String)
    
}

public class RemoteTransportServer {
    
    // MARK: - Private Properties
    
    public let serviceName: String
    public let serviceType: String
    public let port: NWEndpoint.Port
    
    public weak var delegate: RemoteTransportServerDelegate?
    
    private var listener: NWListener?
    private(set) var isStarted = false
    private var connections: [ConnectionId: RemoteTransport.Connection] = [:]

    private(set) var listenerState: NWListener.State = .cancelled
    
    // MARK: - Initialization
    
    public init(serviceName: String = Host.current().localizedName,
                port: UInt16? = nil,
                serviceType: String = Configuration.defaultServiceType) {
        self.port = (port != nil ? .init(rawValue: port!) : .any)
        self.serviceName = serviceName
        self.serviceType = serviceType
    }
    
    // MARK: - Public Functions
    
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
    
    private func didUpdateState(_ newState: NWListener.State) {
        print("Listener did enter state \(newState)")
        self.listenerState = newState
        if case .failed = newState {
            self.scheduleListenerRetry()
        }
    }
    
}

extension RemoteTransportServer {
    
    struct ConnectionId: Hashable {
        let id: ObjectIdentifier
        
        init(_ connection: RemoteTransport.Connection) {
            self.id = ObjectIdentifier(connection)
        }
    }
    
}
