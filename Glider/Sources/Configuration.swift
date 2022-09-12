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

extension Log {
    
    /// This struct is used to define the properties of a new log instance.
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// You can assign an emoji to your log and use it instead of printing
        /// the `subsystem` for a better overlook.
        /// 
        /// By default is set to `nil`.
        public var subsystemIcon: String?
        
        /// Subsystem helps you to track and identify the logger.
        public var subsystem: LoggerIdentifiable = ""
        
        /// It's used to further distinguish a logger inside the same `subsystem`.
        public var category: LoggerIdentifiable = ""
        
        /// Readable log identifier.
        /// It's a composition of the `subsystem` and `category` properties.
        public var label: String {
            [subsystem.id, category.id]
                .map({
                    $0.wipeCharacters(characters: "\n\r ")
                })
                .filter({
                    $0.isEmpty == false
                })
                .joined(separator: ".")
        }
        
        // Minimum accepted severity level.
        //
        // Messages sent to a logger with a level lower than this will be automatically
        // ignored by the system.
        // By default this value is set to `info`.
        public var level: Level = .info
        
        /// Set the log as enabled or disabled.
        /// Disabled loggers ignore all received messages regardless their severity level.
        public var isEnabled = true
        
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
        public var isSynchronous: Bool
        
        // MARK: - Main Configuration
        
        /// Used to decide whether a given event should be passed along to the receiver transports.
        ///
        /// If at least one of the filter specified (executed in order) return `false`
        /// from `shouldAccept()` function event will be silently ignored when being processed.
        public var filters = [TransportFilter]()
        
        /// List of underlying transport layers which can receive and eventually store messages payload (`Event`).
        public var transports = [Transport]()
        
        /// Strategy used to encode common object formats data when passed as `Codable` object.
        public var serializationStrategies = SerializationStrategies()
        
        // MARK: - Initialization
        
        /// Initialize a new configuration via callback.
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
        
        /// Initialize a new configuration with default settings.
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

/// This protocol is used to offer a type-safe way to declare log identifiers
/// properties `subsystem` and `category`
///
/// While you can use a simple `String` to define the identifier of a log, a more
/// swifty way is to declare an enum conform to this protocol and avoid literals in your code.
/// For example:
///
/// ```swift
/// enum Loggers: String, LoggerIdentifiable {
///    case storage = "storage-layer"
///    case network = "network-layer"
///
///    public static let subsystem = "com.myawesomeapp"
///
///    public var id: String { rawValue }
/// }
/// ```
///
/// And use it to create your new logger instead of passing string literals.
///
/// ```swift
/// let networkLogger = Log {
///    $0.subsystem = Loggers.subsystem
///    $0.category = Loggers.network
///    // other configuration...
/// }
/// ```
///
/// Aside from suggestions your are free to use `$0.subsystem = "com.myawesomeapp"`.
///
public protocol LoggerIdentifiable {
    
    /// Unique identifier of the log.
    var id: String { get }
    
}

extension String: LoggerIdentifiable {
    
    public var id: String {
        self
    }
    
}
