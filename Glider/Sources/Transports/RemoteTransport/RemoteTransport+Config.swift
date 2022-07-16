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

extension RemoteTransport {
    
    public struct Configuration {
        
        public static let defaultServiceType = "_glider._tcp"
        
        // MARK: - Public Properties
        
        /// Is the transport enabled. By default is set to `true`.
        public var isEnabled = true
        
        /// The GCD dispatch queue to use.
        /// If not specified a queue is created for you.
        public var queue: DispatchQueue?
        
        /// Name of the service.
        /// By default is set to `_glider._tcp` but you can configure it.
        public var serviceType: String
        
        /// If specified the remote transport automatically connects to the
        /// server with the specified name and the same `serviceType`.
        public var autoConnectServerName: String?
        
        /// If `autoConnectServerName` when this value is `true` the transport
        /// automatically connects to the first available server of the same type.
        public var autoConnectAvailableServer = false
        
        /// The delay interval to retry connection after a disconnection.
        /// By default is set to `3` seconds.
        public var autoRetryConnectInterval = 3
        
        /// Used default encoder. You should never change it unless you are sure.
        public var encoder: JSONEncoder = .init()
        
        // MARK: - Initialization
        
        /// Initialize a new remote configuration object via builder function.
        ///
        /// - Parameter builder: builder callback.
        public init(serviceType: String = "_glider._tcp", _ builder: ((inout Configuration) -> Void)?) {
            self.serviceType = serviceType
            self.queue = DispatchQueue(label: "com.glider.remote-logger")
            builder?(&self)
        }
        
    }
    
}
