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
import Glider

extension NetworkLogger {
    
    /// Represent the configuration object for network logger request.
    public struct Config {
        
        // MARK: - Public Properties
        
        /// Hosts that will be ignored from being recorded.
        public var ignoredHosts = [String]()
        
        /// This is the dispatch queue which make in order the payload received from different channels.
        /// Typically you don't need to change it, it's assigned automatically at init.
        public var queue: DispatchQueue
        
        /// Identify how the messages must be handled when sent to the logger instance.
        /// Typically you want to set if to `false` in production and `true` in development.
        /// The default behaviour - when not specified - uses the `DEBUG` flag to set the the value `true`.
        ///
        /// DISCUSSION:
        /// In synchronous mode messages are sent directly to the queue and the log function is returned
        /// when recorded is called on each specified transport. This mode is is helpful while debugging,
        /// as it ensures that logs are always up-to-date when debug breakpoints are hit.
        ///
        /// However, synchronous mode can have a negative influence on performance and is
        /// therefore not recommended for use in production code.
        public var isSynchronous: Bool = false
        
        /// Transport where the `NetworkEvent` instances (encapsulated inside `Event` instances) are stored.
        ///
        /// NOTE:
        /// This value is automatically filled when specifying `storage` inside the initialization, but you
        /// can customize as you wish.
        public var transports = [Transport]()
        
        // MARK: - Initialization
        
        /// Initialize a new remote configuration object via builder function.
        ///
        /// - Parameter builder: builder callback.
        public init(storage: Storage, _ builder: ((inout Config) -> Void)?) {
            self.queue = DispatchQueue(label: "glider.networklogger.queue.\(UUID().uuidString)")
            builder?(&self)
        }
        
    }
    
}

extension NetworkLogger.Config {
    
    public enum Storage {
        case inMemory(limit: Int)
        case database(fileURL: URL)
        case folder(url: URL)
    }
    
}
