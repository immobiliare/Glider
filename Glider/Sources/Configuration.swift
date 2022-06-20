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

extension Log {
    
    /// This struct allows you to define the configuration of a new log instance.
    public struct Configuration {
        
        // MARK: - Log Initial Configuration
        
        /// Subsystem of the log.
        public var subsystem: LogUUID = ""
        
        /// Category identiifer of the log.
        public var category: LogUUID = ""
        
        // Minimum severity level for this logger.
        // Messages sent to a logger with a level lower than this will be automatically
        // ignored by the system. By default this value is set to `info`.
        public var level: Level = .info
        
        /// Defines if a log is active and can receive messages.
        /// By default is `true`.
        public var isEnabled = true
        
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
        public var isSynchronous: Bool
        
        // MARK: - Main Configuration
        
        /// Used to decide whether a given event should be passed along to the receiver recorders.
        /// If at least one of the filter specified (executed in order) return `false`
        /// from `shouldWrite()` function event will be silently ignored when being processed.
        public var filters = [TransportFilter]()
        
        /// List of underlying transport layers which can receive and eventually store events.
        public var transports = [Transport]()
        
        // MARK: - Extra Configuration

        /// Strategy used to encode common object formats data when passed as encodable object.
        public var serializationStrategies = SerializationStrategies()
        
        /// This is the dispatch queue which make in order the payload received from different channels.
        /// Usually you don't need to specify it manually, a new `.background` serial queue is created automatically
        /// when a new configuration is created.
        public var acceptQueue: DispatchQueue = .init(label: "com.glider.acceptqueue", qos: .background, attributes: [])
        
        // MARK: - Initialization
        
        /// Initialize a new configuration with configuration callback.
        ///
        /// - Parameter builder: builder callback.
        public init(_ builder: ((inout Configuration) -> Void)) {
            #if DEBUG
            self.isSynchronous = true
            #else
            self.isSynchronous = false
            #endif
            
            builder(&self)
        }
        
        /// Initialize a new configuration.
        public init() {
            #if DEBUG
            self.isSynchronous = true
            #else
            self.isSynchronous = false
            #endif
        }
        
    }
    
}

// MARK: - Extras

public protocol LogUUID: CustomStringConvertible { }

extension String: LogUUID {}

