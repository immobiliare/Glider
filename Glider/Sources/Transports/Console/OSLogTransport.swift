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

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
import Foundation
import Darwin.C.stdio
import os.log

/// The `OSLogTransport` is an implemention of the `Transport` protocol that
/// records log entries using the new unified logging system available
/// as of iOS 10.0, macOS 10.12, tvOS 10.0, and watchOS 3.0.
///
/// Read more [here](https://developer.apple.com/documentation/os/logging).
open class OSLogTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Configuration used by the trasnport.
    public let configuration: Configuration
    
    /// Is the transport enabled.
    public var isEnabled: Bool = true
    
    /// Minumum accepted level for this transport.
    /// `nil` means every passing message level is accepted.
    open var minimumAcceptedLevel: Level? = nil
    
    // The `OSLog` used to perform logging.
    public let log: OSLog
    
    // The `DispatchQueue` to use for the recorder.
    open var queue: DispatchQueue
    
    // MARK: - Initialization
    
    /// Initialize a new `OSLogTransport` with a given configuration.
    ///
    /// - Parameter configuration: configuration.
    public init?(configuration: Configuration) throws {
        guard #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) else {
            throw GliderError(message: "OSLog is not supported in this platform")
        }
        
        self.configuration = configuration
        self.isEnabled = configuration.isEnabled
        self.minimumAcceptedLevel = configuration.minimumAcceptedLevel
        self.log = OSLog(subsystem: configuration.subsystem, category: configuration.category)
        self.queue = configuration.queue
    }
    
    /// Initialize a new `OSLogTransport` with a given configuration specified by a callback function..
    ///
    /// The initializer may fail  when `OSLog` is not supported.
    /// - Parameter builder: configuration function.
    public convenience init?(_ builder: ((inout Configuration) -> Void)? = nil) throws {
        try self.init(configuration: Configuration(builder))
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {        
        guard #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) else {
            // things should never get this far; failable initializers should prevent this condition
            print("os.log module not supported on this platform")
            return false
        }
        
        guard let message = configuration.formatters.format(event: event)?.asString(),
              message.isEmpty == false else {
            return false
        }

        let level = configuration.levelTranslator.osLogTypeForEvent(event)
        os_log("%{public}@", log: self.log, type: level, message)
        
        return false
    }
    
}

// MARK: - Configuration

extension OSLogTransport {
    
    /// Represent the configuration settings used to create a new `OSLogTransport` instance.
    public struct Configuration {
        
        // MARK: - Public Properties
        
        /// Is the transport enabled. By default is set to `true`.
        public var isEnabled = true
        
        /// The name of the subsystem performing the logging.
        /// Defaults to `Glider`.
        public var category: String = "Glider"
        
        /// The name of the subsystem performing the logging.
        /// Defaults to the empty string (`""`) if not specified.
        public var subsystem: String = ""
        
        /// Defines how the Glider's `Level` of an event are translated to the relative `OSLogType`.
        /// By default is set to `default`.
        public var levelTranslator: LevelTranslator = .`default`
        
        /// Formatters.
        public var formatters = [EventMessageFormatter]()
        
        // The `DispatchQueue` to use for the recorder.
        public var queue: DispatchQueue

        /// Minumum accepted level for this transport.
        /// `nil` means every passing message level is accepted.
        public var minimumAcceptedLevel: Level? = nil
        
        // MARK: - Initialization
        
        public init(_ builder: ((inout Configuration) -> Void)?) {
            self.queue = DispatchQueue(label: String(describing: type(of: self)), attributes: [])
            builder?(&self)
        }
        
    }
    
}

// MARK: - LevelTranslator

extension OSLogTransport {
    
    /// Specifies the manner in which an `OSLogType` is selected to represent a
    /// given `Event`'s `level`. This happens because there is not an exact one-to-one
    /// mapping between `OSLogType` and `Level` values,
    /// `LevelTranslator` provides a mechanism for deriving the appropriate `OSLogType`
    /// for a given `Event`.
    ///
    /// - `default`: The most direct translation. This value strikes a sensible balance between the higher-overhead logging
    ///              provided by `.strict` and the more ephemeral logging of `.relaxed`.
    ///
    ///              Level|OSLogType
    ///              -----------|---------
    ///              `.debug`   |`.debug`
    ///              `.info`    |`.info`
    ///              `.notice`  |`.info`
    ///              `.warning` |`.info`
    ///              `.error`   |`.error`
    ///              `.critical`|`.error`
    ///              `.alert`   |`.fault`
    ///              `.emergecy`|`.fault`
    ///
    /// - `strict`: A strict translation from a `Event`'s `level` to an `OSLogType` value.
    ///             Warnings are treated as errors; errors are treated as faults.
    ///
    ///              Level|OSLogType
    ///              -----------|---------
    ///              `.debug`   |`.debug`
    ///              `.info`    |`.info`
    ///              `.notice`  |`.info`
    ///              `.warning` |`.error`
    ///              `.error`   |`.error`
    ///              `.critical`|`.fault`
    ///              `.alert`   |`.fault`
    ///              `.emergecy`|`.fault`
    ///
    /// - `relaxed`: A relaxed translation from a `LogEntry`'s `level` to an
    ///              `OSLogType` value. Nothing is treated as fault; only emergency is mapped as an error.
    ///
    ///              Level|OSLogType
    ///              -----------|---------
    ///              `.debug`   |`.debug`
    ///              `.info`    |`.debug`
    ///              `.notice`  |`.info`
    ///              `.warning` |`.info`
    ///              `.error`   |`.info`
    ///              `.critical`|`.info`
    ///              `.alert`   |`.info`
    ///              `.emergecy`|`.error`
    ///
    /// - `allAsDefault`: `OSLogType.default` is used for all messages.
    /// - `allAsInfo`: `OSLogType.info` is used for all messages.
    /// - `allAsDebug`: `OSLogType.debug` is used for all messages.
    /// - `custom`: perform a custom mapping.
    public enum LevelTranslator {
        case `default`
        case strict
        case relaxed
        case allAsDefault
        case allAsInfo
        case allAsDebug
        case custom((Event) -> OSLogType)
        
        fileprivate func osLogTypeForEvent(_ event: Event) -> OSLogType {
            switch self {
            case .allAsDebug:
                return .debug
            case .allAsInfo:
                return .info
            case .allAsDefault:
                return .`default`
            case .custom(let translator):
                return translator(event)
            case .`default`:
                switch event.level {
                case .trace: return .debug
                case .debug: return .debug
                case .info: return .info
                case .notice: return .info
                case .warning: return .info
                case .error: return .error
                case .critical: return .error
                case .alert: return .fault
                case .emergency: return .fault
                }
            case .strict:
                switch event.level {
                case .trace: return .debug
                case .debug: return .debug
                case .info: return .info
                case .notice: return .info
                case .warning: return .error
                case .error: return .error
                case .critical: return .fault
                case .alert: return .fault
                case .emergency: return .fault
                }
            case .relaxed:
                switch event.level {
                case .trace: return .debug
                case .debug: return .debug
                case .info: return .debug
                case .notice: return .info
                case .warning: return .info
                case .error: return .info
                case .critical: return .info
                case .alert: return .info
                case .emergency: return .error
                }
            }
        }
    }
    
}
#endif
