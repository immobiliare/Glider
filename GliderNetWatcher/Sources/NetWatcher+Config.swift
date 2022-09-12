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

import Foundation
import Glider

extension NetWatcher {
    
    /// Represent the configuration object for `NetWatcher`.
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
        /// In synchronous mode messages are sent directly to the queue and the log function is returned
        /// when recorded is called on each specified transport. This mode is is helpful while debugging,
        /// as it ensures that logs are always up-to-date when debug breakpoints are hit.
        ///
        /// However, synchronous mode can have a negative influence on performance and is
        /// therefore not recommended for use in production code.
        public var isSynchronous: Bool = false
        
        /// Transport where the `NetworkEvent` instances (encapsulated inside `Event` instances) are stored.
        ///
        /// This value is automatically filled when specifying `storage` inside the initialization, but you
        /// can customize as you wish.
        public var transports = [Transport]()
        
        // MARK: - Initialization
        
        /// Initialize a new remote configuration object via builder function.
        ///
        /// - Parameter builder: builder callback.
        public init(storage: Storage, _ builder: ((inout Config) -> Void)? = nil) throws {
            self.transports = try [storage.transportInstance()]
            self.queue = DispatchQueue(label: "glider.networklogger.queue.\(UUID().uuidString)")
            builder?(&self)
        }
        
    }
    
}

// MARK: - Storage Configuration

extension NetWatcher.Config {
    
    /// Identify the destination used to redirect sniffed network activities.
    public enum Storage {
        /// a compact archive file powered by SQLite3 where to store each recorded network call.
        case archive(NetArchiveTransport.Configuration)
        /// a directory where each file correspond to a single network call.
        case sparseFiles(NetSparseFilesTransport.Configuration)
        /// a custom transport layer.
        case custom(Transport)
        
        internal func transportInstance() throws -> Transport {
            switch self {
            case .archive(let config):
                return try NetArchiveTransport(configuration: config)
                
            case .sparseFiles(let config):
                return try NetSparseFilesTransport(configuration: config)
                
            case .custom(let transport):
                return transport
                
            }
        }
        
    }
    
}
