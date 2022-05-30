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
import Darwin.C.stdio
import os.log

/// The `OSLogTransport` is an implemention of the `Transport` protocol that
/// records log entries using the new unified logging system available
/// as of iOS 10.0, macOS 10.12, tvOS 10.0, and watchOS 3.0.
public class OSLogTransport: Transport {
    
    // MARK: - Public Properties
    
    /// Defines how the Glider's `Level` of an event are translated to the relative `OSLogType`.
    /// By default is set to `default`.
    public var levelTranslator: LevelTranslator = .`default`
    
    /// Formatters.
    public var formatters: [EventFormatter]
    
    // The `OSLog` used to perform logging.
    public let log: OSLog
    
    // The GCD queue used by the receiver to record messages.
    public var queue: DispatchQueue?
    
    // MARK: - Initialization
    
    /// Initialize a new `OSLogTransport`.
    ///
    /// NOTE: The initializer may fail  when OSLog is not supported.
    ///
    ///
    /// - Parameters:
    ///   - formatters: formatters to use.
    ///   - subsystem: The name of the subsystem performing the logging.
    ///                Defaults to the empty string (`""`) if not specified.
    ///   - queue : The GCD queue that should be used for logging actions related to the receiver.
    public init?(formatters: [EventFormatter],
                 subsystem: String = "",
                 queue: DispatchQueue? = nil) {
        guard #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) else {
            return nil
        }
        
        self.log = OSLog(subsystem: subsystem, category: "CleanroomLogger")
        self.formatters = formatters
        self.queue = queue ?? DispatchQueue(label: String(describing: type(of: self)))
    }
    
    // MARK: - Conformance
    
    public func record(event: Event) -> Bool {
        guard #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) else {
            // things should never get this far; failable initializers should prevent this condition
            print("os.log module not supported on this platform")
            return false
        }
        
        guard let message = formatters.format(event: event)?.asString(),
              message.isEmpty == false else {
            return false
        }

        let level = levelTranslator.osLogTypeForEvent(event)
        os_log("%{public}@", log: self.log, type: level, message)
        
        return false
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
