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
public class WebSocketTransportServer: Transport {
    
    // MARK: - Public Properties
    
    /// GCD queue
    public var queue: DispatchQueue?
    
    /// Configuration.
    public let configuration: Configuration
    
    // MARK: - Private Properties
    
    // MARK: - Initialization
    
    public func record(event: Event) -> Bool {
        true
    }
    
    
}

// MARK: - WebSocketTransportServer.Configuration

extension WebSocketTransportServer {
    
    public struct Configuration {
        
        /// When set the WebSocketTransportServer service will be also
        /// published over the local network via Bonjour services.
        /// This allows local clients to connect.
        public var bonjourPublish: BonjourPublishConfiguration?
        
        
    }
    
    public struct BonjourPublishConfiguration {
        
    }
    
}
