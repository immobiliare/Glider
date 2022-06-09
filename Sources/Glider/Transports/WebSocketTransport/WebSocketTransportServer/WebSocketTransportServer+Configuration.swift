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

// MARK: - WebSocketTransportServer.Configuration

/// The `WebSocketTransportServer` create a websocket server instance.
/// One or more peers can connect
/// to the server in order to receive messages.
/// Any message sent to the server is ignored.
extension WebSocketTransportServer {
    
    public struct Configuration {
        
        /// When set the WebSocketTransportServer service will be also
        /// published over the local network via Bonjour services.
        /// This allows local clients to connect.
        public var bonjourPublish: BonjourPublishConfiguration?
        
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

// MARK: - BonjourPublishConfiguration

extension WebSocketTransportServer {
    
    public struct BonjourPublishConfiguration {
        
        /// Type of service.
        let type: ServiceType
        
        /// Domain name.
        let domain: String
        
        /// Name.
        let name: String
        
        /// Port.
        let port: Int32
        
        /// Service identifier.
        let identifier: String
        
        /// Additional service info.
        let userInfo: [String: String]
    }
    
}

// MARK: - ServiceType

extension WebSocketTransportServer.BonjourPublishConfiguration {
    
    /// Type of exposed service.
    /// - `tcp`: TCP based service.
    /// - `udp`: UDP based service.
    public enum ServiceType {
        case tcp(String)
        case udp(String)
        
        public var description: String {
            switch self {
            case .tcp(let name):
                return "_\(name)._tcp"
            case .udp(let name):
                return "_\(name)._udp"
            }
        }
    }
    
}
