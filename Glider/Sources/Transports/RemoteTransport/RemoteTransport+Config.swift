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
        
        // MARK: - Public Properties
        
        /// The GCD dispatch queue to use.
        /// If not specified a queue is created for you.
        var queue: DispatchQueue?
        
        /// Name of the service.
        /// By default is set to `_glider._tcp` but you can configure it.
        var serviceType = "_glider._tcp"
        
        /// The delay interval to retry connection after a disconnection.
        /// By default is set to `3` seconds.
        var autoRetryConnectInterval = 3
        
        // MARK: - Initialization
        
        /// Initialize a new remote configuration object via builder function.
        ///
        /// - Parameter builder: builder callback.
        public init(_ builder: ((inout Configuration) -> Void)?) {
            self.queue = DispatchQueue(label: "com.glider.remote-logger")
            builder?(&self)
        }
        
    }
    
}
